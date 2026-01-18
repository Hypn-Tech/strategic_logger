import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import '../../core/isolate_manager.dart';
import '../../core/log_queue.dart';
import '../../core/performance_monitor.dart';
import '../../enums/log_level.dart';
import '../log_strategy.dart';

/// A [LogStrategy] implementation that sends logs to Datadog using the v2 API.
///
/// This strategy provides integration with Datadog's logging service,
/// allowing for centralized log management and analysis. It supports
/// structured logging with metadata and context information.
///
/// Features:
/// - HTTP-based log transmission to Datadog v2 API
/// - Gzip compression for reduced network overhead
/// - Structured logging with metadata and context
/// - Batch processing for efficiency
/// - Error handling and retry logic
/// - Performance monitoring
///
/// Example:
/// ```dart
/// var datadogStrategy = DatadogLogStrategy(
///   apiKey: 'your-datadog-api-key',
///   service: 'my-app',
///   env: 'production',
///   enableCompression: true, // Default: true
/// );
/// await logger.initialize(strategies: [datadogStrategy]);
/// await logger.log("Application started.", context: {'userId': 123});
/// ```
class DatadogLogStrategy extends LogStrategy {
  final String apiKey;
  final String service;
  final String env;
  final String? host;
  final String? source;
  final String? tags;
  final String datadogUrl;
  final bool enableCompression;
  final int batchSize;
  final Duration batchTimeout;
  final int maxRetries;
  final Duration retryDelay;

  final List<Map<String, dynamic>> _batch = [];
  Timer? _batchTimer;
  final HttpClient _httpClient = HttpClient();

  /// Constructs a [DatadogLogStrategy].
  ///
  /// [apiKey] - Your Datadog API key (required)
  /// [service] - Service name for the logs (required)
  /// [env] - Environment name (required)
  /// [host] - Host name (optional, defaults to platform hostname)
  /// [source] - Source name (optional, defaults to 'dart')
  /// [tags] - Additional tags as comma-separated string (optional, e.g., 'team:mobile,version:1.0.0')
  /// [datadogUrl] - Datadog API URL (defaults to v2 endpoint for US region)
  /// [enableCompression] - Enable gzip compression (default: true)
  /// [batchSize] - Number of logs to batch before sending (default: 100)
  /// [batchTimeout] - Maximum time to wait before sending batch (default: 5 seconds)
  /// [maxRetries] - Maximum number of retry attempts (default: 3)
  /// [retryDelay] - Delay between retry attempts (default: 1 second)
  /// [useIsolate] - Whether to use isolates for batch preparation (JSON + compression).
  ///   Defaults to TRUE because batch processing is heavy.
  /// [logLevel] - Minimum log level to process
  /// [supportedEvents] - Specific events to handle
  DatadogLogStrategy({
    required this.apiKey,
    required this.service,
    required this.env,
    this.host,
    this.source,
    this.tags,
    this.datadogUrl = 'https://http-intake.logs.datadoghq.com/api/v2/logs',
    this.enableCompression = true,
    this.batchSize = 100,
    this.batchTimeout = const Duration(seconds: 5),
    this.maxRetries = 3,
    this.retryDelay = const Duration(seconds: 1),
    bool useIsolate = true, // Default: TRUE (batch + compression are heavy)
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

  /// Logs a message or event to Datadog
  @override
  Future<void> log(LogEntry entry) async {
    await _logToDatadog(entry);
  }

  /// Logs an info message to Datadog
  @override
  Future<void> info(LogEntry entry) async {
    await _logToDatadog(entry);
  }

  /// Logs an error to Datadog
  @override
  Future<void> error(LogEntry entry) async {
    await _logToDatadog(entry);
  }

  /// Logs a fatal error to Datadog
  @override
  Future<void> fatal(LogEntry entry) async {
    await _logToDatadog(entry);
  }

  /// Internal method to log to Datadog
  Future<void> _logToDatadog(LogEntry entry) async {
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
        'Error in DatadogLogStrategy: $e',
        name: 'DatadogLogStrategy',
        error: e,
        stackTrace: stack,
      );
    }
  }

  /// Creates a log entry in Datadog v2 format
  Map<String, dynamic> _createLogEntry(LogEntry entry) {
    // Get hostname (use provided host or try to get system hostname)
    final hostname = host ?? _getHostname();

    // Build the base log entry in Datadog v2 format
    final logEntry = <String, dynamic>{
      'ddsource': source ?? 'dart',
      'ddtags': _buildTags(),
      'hostname': hostname,
      'message': entry.message.toString(),
      'service': service,
      'status': _mapLogLevelToStatus(entry.level),
      'timestamp': entry.timestamp.toUtc().millisecondsSinceEpoch,
    };

    // Add environment
    logEntry['env'] = env;

    // Merge context from entry.context and event.parameters
    // Context fields are added directly to the log object for indexing
    if (entry.context != null && entry.context!.isNotEmpty) {
      // Add context fields directly to the log entry
      entry.context!.forEach((key, value) {
        // Use a prefix to avoid conflicts with Datadog reserved fields
        if (!_isReservedField(key)) {
          logEntry[key] = value;
        } else {
          logEntry['context.$key'] = value;
        }
      });
    }

    // Add event parameters if present
    if (entry.event?.parameters != null &&
        entry.event!.parameters!.isNotEmpty) {
      entry.event!.parameters!.forEach((key, value) {
        if (!_isReservedField(key)) {
          logEntry[key] = value;
        } else {
          logEntry['event.$key'] = value;
        }
      });
    }

    // Add event information
    if (entry.event != null) {
      logEntry['event_name'] = entry.event!.eventName;
      if (entry.event!.eventMessage != null) {
        logEntry['event_message'] = entry.event!.eventMessage;
      }
    }

    // Add stack trace for errors
    if (entry.stackTrace != null) {
      logEntry['error.stack'] = entry.stackTrace.toString();
    }

    // Add level for filtering
    logEntry['level'] = entry.level.name;

    return logEntry;
  }

  /// Checks if a field name is a Datadog reserved field
  bool _isReservedField(String key) {
    const reservedFields = {
      'ddsource',
      'ddtags',
      'hostname',
      'message',
      'service',
      'status',
      'timestamp',
      'env',
      'level',
      'event_name',
      'event_message',
      'error.stack',
    };
    return reservedFields.contains(key.toLowerCase());
  }

  /// Builds the ddtags string from tags parameter
  String _buildTags() {
    final tagList = <String>[];
    if (tags != null && tags!.isNotEmpty) {
      tagList.addAll(tags!.split(',').map((t) => t.trim()));
    }
    // Add environment tag
    tagList.add('env:$env');
    return tagList.join(',');
  }

  /// Gets the system hostname
  String _getHostname() {
    try {
      return Platform.localHostname;
    } catch (e) {
      return 'unknown';
    }
  }

  /// Maps LogLevel to Datadog status
  String _mapLogLevelToStatus(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
      case LogLevel.info:
        return 'info';
      case LogLevel.warning:
        return 'warn';
      case LogLevel.error:
      case LogLevel.fatal:
        return 'error';
      case LogLevel.none:
        return 'info';
    }
  }

  /// Sends the current batch to Datadog
  Future<void> _sendBatch() async {
    if (_batch.isEmpty) return;

    final batchToSend = List<Map<String, dynamic>>.from(_batch);
    _batch.clear();

    await performanceMonitor.measureOperation('sendDatadogBatch', () async {
      await _sendBatchWithRetry(batchToSend);
    });
  }

  /// Sends batch with retry logic
  Future<void> _sendBatchWithRetry(List<Map<String, dynamic>> batch) async {
    int attempts = 0;

    while (attempts < maxRetries) {
      try {
        await _sendBatchToDatadog(batch);
        return; // Success
      } catch (e) {
        attempts++;
        if (attempts >= maxRetries) {
          developer.log(
            'Failed to send batch to Datadog after $maxRetries attempts: $e',
            name: 'DatadogLogStrategy',
            error: e,
          );
          rethrow;
        }

        // Wait before retry with exponential backoff
        await Future.delayed(retryDelay * attempts);
      }
    }
  }

  /// Sends batch to Datadog v2 API with optional gzip compression
  Future<void> _sendBatchToDatadog(List<Map<String, dynamic>> batch) async {
    final request = await _httpClient.postUrl(Uri.parse(datadogUrl));

    // Set headers
    request.headers.set('Content-Type', 'application/json');
    request.headers.set('DD-API-KEY', apiKey);

    List<int> bodyBytes;

    if (useIsolate) {
      // Prepare batch in isolate (JSON + optional compression)
      try {
        final prepared = await isolateManager.prepareBatch(
          batch: batch,
          compress: enableCompression,
        );
        bodyBytes = (prepared['body'] as List).cast<int>();
        if (prepared['isCompressed'] == true) {
          request.headers.set('Content-Encoding', 'gzip');
        }
      } catch (e) {
        // Fallback to main thread processing
        bodyBytes = _prepareBatchDirect(batch);
        if (enableCompression) {
          request.headers.set('Content-Encoding', 'gzip');
        }
      }
    } else {
      // Direct processing on main thread
      bodyBytes = _prepareBatchDirect(batch);
      if (enableCompression) {
        request.headers.set('Content-Encoding', 'gzip');
      }
    }

    // Write body
    request.contentLength = bodyBytes.length;
    request.add(bodyBytes);
    final response = await request.close();

    // Read response to ensure connection is closed
    await response.drain();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Datadog API returned status ${response.statusCode}: ${response.reasonPhrase}',
      );
    }
  }

  /// Prepares batch directly on main thread (fallback or when useIsolate=false)
  List<int> _prepareBatchDirect(List<Map<String, dynamic>> batch) {
    final jsonBody = jsonEncode(batch);
    if (enableCompression) {
      final encoder = GZipCodec();
      return encoder.encode(utf8.encode(jsonBody));
    }
    return utf8.encode(jsonBody);
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
