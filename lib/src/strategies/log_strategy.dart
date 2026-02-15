import '../core/log_queue.dart';
import '../enums/log_level.dart';
import '../events/log_event.dart';

/// An abstract class that represents a logging strategy.
///
/// This class provides the structure for implementing various logging strategies,
/// allowing for detailed control over how messages, errors, and fatal errors are logged
/// depending on their level and the events they are associated with.
///
/// **Recommended (v4.0.0+):** Override only `handleLog()` for uniform handling:
/// ```dart
/// class MyStrategy extends LogStrategy {
///   @override
///   Future<void> handleLog(LogEntry entry) async {
///     // Use entry.message, entry.mergedContext, entry.event, etc.
///     print('${entry.level}: ${entry.message}');
///   }
/// }
/// ```
///
/// **Per-level handling:** Override `log()`, `info()`, `error()`, and `fatal()`
/// for different behavior per log level.
abstract class LogStrategy {
  /// The minimum log level that this strategy handles for logging.
  LogLevel logLevel;

  /// The log level set by the logger using this strategy. Used to determine if a message should be logged.
  LogLevel loggerLogLevel;

  /// A list of specific [LogEvent] types that this strategy supports. If null, all events are considered supported.
  List<LogEvent>? supportedEvents;

  /// Whether this strategy should use isolates for heavy operations.
  ///
  /// Each strategy defines its own default based on operation weight.
  /// Users can override at initialization time.
  ///
  /// Example:
  /// ```dart
  /// // Use default (true for most strategies, false for Console)
  /// DatadogLogStrategy(apiKey: 'key', service: 'app', env: 'prod')
  ///
  /// // Override to disable isolate
  /// DatadogLogStrategy(apiKey: 'key', service: 'app', env: 'prod', useIsolate: false)
  /// ```
  final bool useIsolate;

  /// Constructs a [LogStrategy].
  ///
  /// [loggerLogLevel] - The log level of the logger. Defaults to [LogLevel.none].
  /// [logLevel] - The minimum log level that this strategy will handle. Defaults to [LogLevel.none].
  /// [supportedEvents] - Optional. Specifies the events that are explicitly supported by this strategy.
  /// [useIsolate] - Whether to use isolates for heavy operations. Defaults to true.
  ///   Each concrete strategy may override this default based on operation weight.
  LogStrategy({
    this.loggerLogLevel = LogLevel.none,
    this.logLevel = LogLevel.none,
    this.supportedEvents,
    this.useIsolate = true,
  });

  /// Determines whether a log operation should proceed based on the event and log level.
  ///
  /// [event] - Optional. The specific log event being checked. If provided, the method checks
  /// whether the event is supported by this strategy.
  /// Returns true if the log should be processed, false otherwise.
  bool shouldLog({LogEvent? event}) {
    if (event != null) {
      return supportedEvents?.contains(event) ?? true;
    } else {
      return logLevel.index <= loggerLogLevel.index;
    }
  }

  /// Main log handler - override this single method for uniform handling of all log levels.
  ///
  /// By default, `log()`, `info()`, `error()`, and `fatal()` delegate to this method.
  /// Override only this method when your strategy handles all levels the same way.
  ///
  /// For different behavior per level, override the individual methods instead.
  ///
  /// Example:
  /// ```dart
  /// class MyStrategy extends LogStrategy {
  ///   @override
  ///   Future<void> handleLog(LogEntry entry) async {
  ///     if (!shouldLog(event: entry.event)) return;
  ///     final context = entry.mergedContext;
  ///     await sendToMyService(entry.message, context);
  ///   }
  /// }
  /// ```
  Future<void> handleLog(LogEntry entry) async {
    // Default: no-op. Override this in your strategy.
  }

  /// Logs a debug or general message.
  ///
  /// By default, delegates to [handleLog]. Override for level-specific behavior.
  ///
  /// [entry] - The complete log entry containing message, level, timestamp, context, and event.
  Future<void> log(LogEntry entry) async => handleLog(entry);

  /// Logs an info message.
  ///
  /// By default, delegates to [handleLog]. Override for level-specific behavior.
  ///
  /// [entry] - The complete log entry containing message, level, timestamp, context, and event.
  Future<void> info(LogEntry entry) async => handleLog(entry);

  /// Logs an error.
  ///
  /// By default, delegates to [handleLog]. Override for level-specific behavior.
  ///
  /// [entry] - The complete log entry containing error message, level, timestamp, context, stackTrace, and event.
  Future<void> error(LogEntry entry) async => handleLog(entry);

  /// Logs a fatal error.
  ///
  /// By default, delegates to [handleLog]. Override for level-specific behavior.
  ///
  /// [entry] - The complete log entry containing fatal error message, level, timestamp, context, stackTrace, and event.
  Future<void> fatal(LogEntry entry) async => handleLog(entry);

  /// Provides a string representation of the strategy including its type and log level.
  @override
  String toString() {
    return '$runtimeType(LogLevel: $logLevel)';
  }
}
