import 'dart:convert';
import 'dart:io';

import '../../core/isolate_manager.dart';
import '../../core/log_queue.dart';
import '../../enums/log_level.dart';
import '../http_log_strategy.dart';

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
/// logger.log("Application started.", context: {'userId': 123});
/// ```
class DatadogLogStrategy extends HttpLogStrategy {
  /// Your Datadog API key.
  final String apiKey;

  /// Service name for the logs.
  final String service;

  /// Environment name (e.g., 'production', 'staging').
  final String env;

  /// Host name (optional, defaults to platform hostname).
  final String? host;

  /// Source name (optional, defaults to 'dart').
  final String? source;

  /// Additional tags as comma-separated string (e.g., 'team:mobile,version:1.0.0').
  final String? tags;

  /// Datadog API URL (defaults to v2 endpoint for US region).
  final String datadogUrl;

  /// Enable gzip compression for reduced network overhead.
  final bool enableCompression;

  /// Constructs a [DatadogLogStrategy].
  ///
  /// [apiKey] - Your Datadog API key (required)
  /// [service] - Service name for the logs (required)
  /// [env] - Environment name (required)
  /// [host] - Host name (optional, defaults to platform hostname)
  /// [source] - Source name (optional, defaults to 'dart')
  /// [tags] - Additional tags as comma-separated string (optional)
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
    super.batchSize = 100,
    super.batchTimeout = const Duration(seconds: 5),
    super.maxRetries = 3,
    super.retryDelay = const Duration(seconds: 1),
    super.useIsolate = true,
    super.logLevel = LogLevel.none,
    super.supportedEvents,
  });

  @override
  String get strategyName => 'DatadogLogStrategy';

  @override
  String get endpoint => datadogUrl;

  @override
  Map<String, String> get headers => {'DD-API-KEY': apiKey};

  @override
  Map<String, dynamic> formatLogEntry(LogEntry entry) {
    return _createLogEntry(entry);
  }

  @override
  Future<({List<int> body, Map<String, String> extraHeaders})> prepareBatchBody(
    List<Map<String, dynamic>> batch,
  ) async {
    if (useIsolate) {
      try {
        final prepared = await isolateManager.prepareBatch(
          batch: batch,
          compress: enableCompression,
        );
        final body = (prepared['body'] as List).cast<int>();
        final extraHeaders = <String, String>{};
        if (prepared['isCompressed'] == true) {
          extraHeaders['Content-Encoding'] = 'gzip';
        }
        return (body: body, extraHeaders: extraHeaders);
      } catch (_) {
        // Fallback to direct processing
      }
    }

    final jsonBody = jsonEncode(batch);
    final extraHeaders = <String, String>{};
    if (enableCompression) {
      final encoder = GZipCodec();
      extraHeaders['Content-Encoding'] = 'gzip';
      return (
        body: encoder.encode(utf8.encode(jsonBody)),
        extraHeaders: extraHeaders,
      );
    }
    return (body: utf8.encode(jsonBody), extraHeaders: extraHeaders);
  }

  /// Creates a log entry in Datadog v2 format.
  Map<String, dynamic> _createLogEntry(LogEntry entry) {
    final hostname = host ?? _getHostname();

    final logEntry = <String, dynamic>{
      'ddsource': source ?? 'dart',
      'ddtags': _buildTags(),
      'hostname': hostname,
      'message': entry.message.toString(),
      'service': service,
      'status': _mapLogLevelToStatus(entry.level),
      'timestamp': entry.timestamp.toUtc().millisecondsSinceEpoch,
    };

    logEntry['env'] = env;

    // Add context fields directly (with prefix for reserved field conflicts)
    if (entry.context != null && entry.context!.isNotEmpty) {
      entry.context!.forEach((key, value) {
        if (!_isReservedField(key)) {
          logEntry[key] = value;
        } else {
          logEntry['context.$key'] = value;
        }
      });
    }

    // Add event parameters (with different prefix for reserved field conflicts)
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

    if (entry.event != null) {
      logEntry['event_name'] = entry.event!.eventName;
      if (entry.event!.eventMessage != null) {
        logEntry['event_message'] = entry.event!.eventMessage;
      }
    }

    if (entry.stackTrace != null) {
      logEntry['error.stack'] = entry.stackTrace.toString();
    }

    logEntry['level'] = entry.level.name;

    return logEntry;
  }

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

  String _buildTags() {
    final tagList = <String>[];
    if (tags != null && tags!.isNotEmpty) {
      tagList.addAll(tags!.split(',').map((t) => t.trim()));
    }
    tagList.add('env:$env');
    return tagList.join(',');
  }

  String _getHostname() {
    try {
      return Platform.localHostname;
    } catch (e) {
      return 'unknown';
    }
  }

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
}
