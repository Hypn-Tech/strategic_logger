import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import '../core/log_queue.dart';
import '../core/performance_monitor.dart';
import '../enums/log_level.dart';
import 'log_strategy.dart';

/// Base class for HTTP-based logging strategies.
///
/// Provides shared functionality for strategies that send logs to remote
/// HTTP endpoints, including:
/// - Batch processing with configurable size and timeout
/// - Retry logic with exponential backoff
/// - HttpClient management
/// - Proper resource disposal
///
/// Subclasses only need to implement [formatLogEntry], [endpoint], [headers],
/// and [strategyName] to create a fully functional HTTP logging strategy.
///
/// Example:
/// ```dart
/// class MyHttpStrategy extends HttpLogStrategy {
///   MyHttpStrategy({required this.apiKey})
///       : super(batchSize: 100, batchTimeout: Duration(seconds: 5));
///
///   final String apiKey;
///
///   @override
///   String get strategyName => 'MyHttpStrategy';
///   @override
///   String get endpoint => 'https://api.example.com/logs';
///   @override
///   Map<String, String> get headers => {'Authorization': 'Bearer $apiKey'};
///   @override
///   Map<String, dynamic> formatLogEntry(LogEntry entry) => entry.toMap();
/// }
/// ```
abstract class HttpLogStrategy extends LogStrategy {
  /// Number of log entries to accumulate before sending a batch.
  final int batchSize;

  /// Maximum time to wait before sending an incomplete batch.
  final Duration batchTimeout;

  /// Maximum number of retry attempts for failed batch sends.
  final int maxRetries;

  /// Base delay between retry attempts (multiplied by attempt number).
  final Duration retryDelay;

  final List<Map<String, dynamic>> _batch = [];
  Timer? _batchTimer;
  final HttpClient _httpClient = HttpClient();

  /// Creates an [HttpLogStrategy] with the given configuration.
  HttpLogStrategy({
    this.batchSize = 100,
    this.batchTimeout = const Duration(seconds: 5),
    this.maxRetries = 3,
    this.retryDelay = const Duration(seconds: 1),
    super.useIsolate = true,
    super.logLevel = LogLevel.none,
    super.supportedEvents,
  }) {
    _startBatchTimer();
  }

  /// The name of this strategy, used in log messages for debugging.
  String get strategyName;

  /// The HTTP endpoint URL to send log batches to.
  String get endpoint;

  /// HTTP headers to include with each batch request.
  Map<String, String> get headers;

  /// The performance monitor operation name for batch sends.
  String get performanceOperationName => 'send${strategyName}Batch';

  /// Formats a single [LogEntry] into a map suitable for the target API.
  ///
  /// Subclasses must implement this to format entries according to the
  /// specific API requirements of the target service.
  Map<String, dynamic> formatLogEntry(LogEntry entry);

  /// Prepares the batch body bytes for sending.
  ///
  /// Override this for custom serialization (e.g., gzip compression).
  /// The default implementation JSON-encodes the batch.
  ///
  /// Returns a record with body bytes and optional extra headers.
  Future<({List<int> body, Map<String, String> extraHeaders})> prepareBatchBody(
    List<Map<String, dynamic>> batch,
  ) async {
    final jsonBody = jsonEncode(batch);
    return (body: utf8.encode(jsonBody), extraHeaders: <String, String>{});
  }

  /// Starts the periodic batch timer.
  void _startBatchTimer() {
    _batchTimer = Timer.periodic(batchTimeout, (_) {
      if (_batch.isNotEmpty) {
        _sendBatch();
      }
    });
  }

  @override
  Future<void> handleLog(LogEntry entry) async {
    try {
      if (!shouldLog(event: entry.event)) return;

      final logEntry = formatLogEntry(entry);
      _batch.add(logEntry);

      if (_batch.length >= batchSize) {
        await _sendBatch();
      }
    } catch (e, stack) {
      developer.log(
        'Error in $strategyName: $e',
        name: strategyName,
        error: e,
        stackTrace: stack,
      );
    }
  }

  /// Sends the current batch to the remote endpoint.
  Future<void> _sendBatch() async {
    if (_batch.isEmpty) return;

    final batchToSend = List<Map<String, dynamic>>.from(_batch);
    _batch.clear();

    await performanceMonitor.measureOperation(
      performanceOperationName,
      () async {
        await _sendBatchWithRetry(batchToSend);
      },
    );
  }

  /// Sends a batch with retry logic and exponential backoff.
  Future<void> _sendBatchWithRetry(List<Map<String, dynamic>> batch) async {
    int attempts = 0;

    while (attempts < maxRetries) {
      try {
        await _sendBatchToEndpoint(batch);
        return; // Success
      } catch (e) {
        attempts++;
        if (attempts >= maxRetries) {
          developer.log(
            'Failed to send batch to $strategyName after $maxRetries attempts: $e',
            name: strategyName,
            error: e,
          );
          rethrow;
        }

        // Wait before retry with exponential backoff
        await Future.delayed(retryDelay * attempts);
      }
    }
  }

  /// Sends the batch to the HTTP endpoint.
  Future<void> _sendBatchToEndpoint(List<Map<String, dynamic>> batch) async {
    final request = await _httpClient.postUrl(Uri.parse(endpoint));

    // Set base headers
    request.headers.set('Content-Type', 'application/json');
    for (final entry in headers.entries) {
      request.headers.set(entry.key, entry.value);
    }

    // Prepare body (may use isolate for heavy operations)
    final prepared = await _prepareBatchWithIsolate(batch);

    // Set extra headers (e.g., Content-Encoding: gzip)
    for (final entry in prepared.extraHeaders.entries) {
      request.headers.set(entry.key, entry.value);
    }

    // Write body
    request.contentLength = prepared.body.length;
    request.add(prepared.body);
    final response = await request.close();

    // Read response to ensure connection is closed
    await response.drain();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        '$strategyName API returned status ${response.statusCode}: ${response.reasonPhrase}',
      );
    }
  }

  /// Prepares batch, potentially using isolate for heavy operations.
  Future<({List<int> body, Map<String, String> extraHeaders})>
  _prepareBatchWithIsolate(List<Map<String, dynamic>> batch) async {
    if (useIsolate) {
      try {
        return await prepareBatchBody(batch);
      } catch (e) {
        // Fallback to direct processing
        final jsonBody = jsonEncode(batch);
        return (body: utf8.encode(jsonBody), extraHeaders: <String, String>{});
      }
    }
    return prepareBatchBody(batch);
  }

  /// Forces sending of all pending logs.
  Future<void> flush() async {
    if (_batch.isNotEmpty) {
      await _sendBatch();
    }
  }

  /// Disposes the strategy and cleans up resources.
  void dispose() {
    _batchTimer?.cancel();
    _httpClient.close();
    flush();
  }
}
