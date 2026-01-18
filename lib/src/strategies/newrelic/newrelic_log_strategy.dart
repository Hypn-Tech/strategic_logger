import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import '../../core/isolate_manager.dart';
import '../../core/log_queue.dart';
import '../../core/performance_monitor.dart';
import '../../enums/log_level.dart';
import '../log_strategy.dart';

/// A [LogStrategy] implementation that sends logs to New Relic.
///
/// This strategy provides integration with New Relic's logging service,
/// allowing for centralized log management and analysis. It supports
/// structured logging with metadata and context information.
///
/// Features:
/// - HTTP-based log transmission to New Relic
/// - Structured logging with metadata
/// - Batch processing for efficiency
/// - Error handling and retry logic
/// - Performance monitoring
///
/// Example:
/// ```dart
/// var newrelicStrategy = NewRelicLogStrategy(
///   licenseKey: 'your-newrelic-license-key',
///   appName: 'my-app',
/// );
/// var logger = StrategicLogger(strategies: [newrelicStrategy]);
/// logger.log("Application started.");
/// ```
class NewRelicLogStrategy extends LogStrategy {
  final String licenseKey;
  final String appName;
  final String? host;
  final String? environment;
  final String newrelicUrl;
  final int batchSize;
  final Duration batchTimeout;
  final int maxRetries;
  final Duration retryDelay;

  final List<Map<String, dynamic>> _batch = [];
  Timer? _batchTimer;
  final HttpClient _httpClient = HttpClient();

  /// Constructs a [NewRelicLogStrategy].
  ///
  /// [licenseKey] - Your New Relic license key (required)
  /// [appName] - Application name (required)
  /// [host] - Host name (optional)
  /// [environment] - Environment name (optional)
  /// [newrelicUrl] - New Relic API URL (defaults to US region)
  /// [batchSize] - Number of logs to batch before sending
  /// [batchTimeout] - Maximum time to wait before sending batch
  /// [maxRetries] - Maximum number of retry attempts
  /// [retryDelay] - Delay between retry attempts
  /// [useIsolate] - Whether to use isolates for batch preparation (JSON serialization).
  ///   Defaults to TRUE because batch processing is heavy.
  /// [logLevel] - Minimum log level to process
  /// [supportedEvents] - Specific events to handle
  NewRelicLogStrategy({
    required this.licenseKey,
    required this.appName,
    this.host,
    this.environment,
    this.newrelicUrl = 'https://log-api.newrelic.com/log/v1',
    this.batchSize = 100,
    this.batchTimeout = const Duration(seconds: 5),
    this.maxRetries = 3,
    this.retryDelay = const Duration(seconds: 1),
    bool useIsolate = true, // Default: TRUE (batch serialization is heavy)
    super.logLevel = LogLevel.none,
    super.supportedEvents,
  }) : super(useIsolate: useIsolate) {
    _startBatchTimer();
  }

  /// Starts the batch timer for automatic log sending
  void _startBatchTimer() {
    _batchTimer = Timer.periodic(batchTimeout, (_) {
      if (_batch.isNotEmpty) {
        _sendBatch();
      }
    });
  }

  /// Logs a message or event to New Relic
  @override
  Future<void> log(LogEntry entry) async {
    await _logToNewRelic(entry);
  }

  /// Logs an info message to New Relic
  @override
  Future<void> info(LogEntry entry) async {
    await _logToNewRelic(entry);
  }

  /// Logs an error to New Relic
  @override
  Future<void> error(LogEntry entry) async {
    await _logToNewRelic(entry);
  }

  /// Logs a fatal error to New Relic
  @override
  Future<void> fatal(LogEntry entry) async {
    await _logToNewRelic(entry);
  }

  /// Internal method to log to New Relic
  Future<void> _logToNewRelic(LogEntry entry) async {
    try {
      if (!shouldLog(event: entry.event)) return;

      final logEntry = _createLogEntry(entry);
      _batch.add(logEntry);

      // Send batch if it reaches the batch size
      if (_batch.length >= batchSize) {
        await _sendBatch();
      }
    } catch (e, stack) {
      developer.log(
        'Error in NewRelicLogStrategy: $e',
        name: 'NewRelicLogStrategy',
        error: e,
        stackTrace: stack,
      );
    }
  }

  /// Creates a log entry for New Relic
  Map<String, dynamic> _createLogEntry(LogEntry entry) {
    final timestamp = entry.timestamp.toUtc();

    // Merge context from entry.context and event.parameters
    final attributes = <String, dynamic>{
      'message': entry.message.toString(),
      'level': entry.level.name,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'appName': appName,
    };

    if (host != null) attributes['host'] = host;
    if (environment != null) attributes['environment'] = environment;

    // Add context fields
    if (entry.context != null && entry.context!.isNotEmpty) {
      entry.context!.forEach((key, value) {
        attributes[key] = value;
      });
    }

    // Add event parameters if present
    if (entry.event?.parameters != null &&
        entry.event!.parameters!.isNotEmpty) {
      entry.event!.parameters!.forEach((key, value) {
        attributes[key] = value;
      });
    }

    // Add event information
    if (entry.event != null) {
      attributes['event_name'] = entry.event!.eventName;
      if (entry.event!.eventMessage != null) {
        attributes['event_message'] = entry.event!.eventMessage;
      }
    }

    // Add stack trace for errors
    if (entry.stackTrace != null) {
      attributes['stack_trace'] = entry.stackTrace.toString();
    }

    return attributes;
  }

  // Deprecated method removed - using _createLogEntry instead
  // This method is no longer used and has been replaced by _createLogEntry
  // _mapLogLevelToNewRelic was also removed as it's no longer needed

  /// Sends the current batch to New Relic
  Future<void> _sendBatch() async {
    if (_batch.isEmpty) return;

    final batchToSend = List<Map<String, dynamic>>.from(_batch);
    _batch.clear();

    await performanceMonitor.measureOperation('sendNewRelicBatch', () async {
      await _sendBatchWithRetry(batchToSend);
    });
  }

  /// Sends batch with retry logic
  Future<void> _sendBatchWithRetry(List<Map<String, dynamic>> batch) async {
    int attempts = 0;

    while (attempts < maxRetries) {
      try {
        await _sendBatchToNewRelic(batch);
        return; // Success
      } catch (e) {
        attempts++;
        if (attempts >= maxRetries) {
          developer.log(
            'Failed to send batch to New Relic after $maxRetries attempts: $e',
            name: 'NewRelicLogStrategy',
            error: e,
          );
          rethrow;
        }

        // Wait before retry
        await Future.delayed(retryDelay * attempts);
      }
    }
  }

  /// Sends batch to New Relic API
  Future<void> _sendBatchToNewRelic(List<Map<String, dynamic>> batch) async {
    final request = await _httpClient.postUrl(Uri.parse(newrelicUrl));

    // Set headers
    request.headers.set('Content-Type', 'application/json');
    request.headers.set('Api-Key', licenseKey);

    String body;

    if (useIsolate) {
      // Prepare batch in isolate (JSON serialization)
      try {
        final prepared = await isolateManager.prepareBatch(
          batch: batch,
          compress: false, // NewRelic doesn't use compression
        );
        body = utf8.decode((prepared['body'] as List).cast<int>());
      } catch (e) {
        // Fallback to main thread processing
        body = jsonEncode(batch);
      }
    } else {
      // Direct processing on main thread
      body = jsonEncode(batch);
    }

    request.write(body);

    final response = await request.close();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('New Relic API returned status ${response.statusCode}');
    }
  }

  /// Forces sending of all pending logs
  Future<void> flush() async {
    if (_batch.isNotEmpty) {
      await _sendBatch();
    }
  }

  /// Disposes the strategy and cleans up resources
  void dispose() {
    _batchTimer?.cancel();
    _httpClient.close();
    flush();
  }
}
