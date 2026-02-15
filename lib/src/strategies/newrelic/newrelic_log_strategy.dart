import 'dart:convert';

import '../../core/isolate_manager.dart';
import '../../core/log_queue.dart';
import '../../enums/log_level.dart';
import '../http_log_strategy.dart';

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
/// await logger.initialize(strategies: [newrelicStrategy]);
/// logger.log("Application started.");
/// ```
class NewRelicLogStrategy extends HttpLogStrategy {
  /// Your New Relic license key.
  final String licenseKey;

  /// Application name.
  final String appName;

  /// Host name (optional).
  final String? host;

  /// Environment name (optional).
  final String? environment;

  /// New Relic API URL (defaults to US region).
  final String newrelicUrl;

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
    super.batchSize = 100,
    super.batchTimeout = const Duration(seconds: 5),
    super.maxRetries = 3,
    super.retryDelay = const Duration(seconds: 1),
    super.useIsolate = true,
    super.logLevel = LogLevel.none,
    super.supportedEvents,
  });

  @override
  String get strategyName => 'NewRelicLogStrategy';

  @override
  String get endpoint => newrelicUrl;

  @override
  Map<String, String> get headers => {'Api-Key': licenseKey};

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
          compress: false, // New Relic doesn't use compression
        );
        final body = utf8.encode(
          utf8.decode((prepared['body'] as List).cast<int>()),
        );
        return (body: body, extraHeaders: <String, String>{});
      } catch (_) {
        // Fallback to direct processing
      }
    }

    return (
      body: utf8.encode(jsonEncode(batch)),
      extraHeaders: <String, String>{},
    );
  }

  /// Creates a log entry for New Relic.
  Map<String, dynamic> _createLogEntry(LogEntry entry) {
    final timestamp = entry.timestamp.toUtc();

    final attributes = <String, dynamic>{
      'message': entry.message.toString(),
      'level': entry.level.name,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'appName': appName,
    };

    if (host != null) attributes['host'] = host;
    if (environment != null) attributes['environment'] = environment;

    // Merge context from entry.context and event.parameters
    final mergedContext = entry.mergedContext;
    if (mergedContext.isNotEmpty) {
      attributes.addAll(mergedContext);
    }

    if (entry.event != null) {
      attributes['event_name'] = entry.event!.eventName;
      if (entry.event!.eventMessage != null) {
        attributes['event_message'] = entry.event!.eventMessage;
      }
    }

    if (entry.stackTrace != null) {
      attributes['stack_trace'] = entry.stackTrace.toString();
    }

    return attributes;
  }
}
