import '../core/log_queue.dart';
import '../enums/log_level.dart';
import '../events/log_event.dart';

/// An abstract class that represents a logging strategy.
///
/// This class provides the structure for implementing various logging strategies,
/// allowing for detailed control over how messages, errors, and fatal errors are logged
/// depending on their level and the events they are associated with.
///
/// **New implementations (v1.4.0+):** Override `log()`, `info()`, `error()`, and `fatal()` methods
/// that receive a complete `LogEntry` object with context.
///
/// **Legacy implementations:** Override `logMessage()` and `logError()` methods for backward
/// compatibility. These methods now receive context automatically.
///
/// Example (new way):
/// ```dart
/// class MyStrategy extends LogStrategy {
///   @override
///   Future<void> log(LogEntry entry) async {
///     // Use entry.message, entry.context, entry.event, etc.
///   }
/// }
/// ```
///
/// Example (legacy way - still works):
/// ```dart
/// class MyLegacyStrategy extends LogStrategy {
///   @override
///   Future<void> logMessage(dynamic message, LogEvent? event, Map<String, dynamic>? context) async {
///     // context is now available automatically!
///   }
/// }
/// ```
abstract class LogStrategy {
  /// The minimum log level that this strategy handles for logging.
  LogLevel logLevel;

  /// The log level set by the logger using this strategy. Used to determine if a message should be logged.
  LogLevel loggerLogLevel;

  /// A list of specific [LogEvent] types that this strategy supports. If null, all events are considered supported.
  List<LogEvent>? supportedEvents;

  /// Constructs a [LogStrategy].
  ///
  /// [loggerLogLevel] - The log level of the logger. Defaults to [LogLevel.none].
  /// [logLevel] - The minimum log level that this strategy will handle. Defaults to [LogLevel.none].
  /// [supportedEvents] - Optional. Specifies the events that are explicitly supported by this strategy.
  LogStrategy({
    this.loggerLogLevel = LogLevel.none,
    this.logLevel = LogLevel.none,
    this.supportedEvents,
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

  /// Logs a message or event.
  ///
  /// **New implementations (v1.4.0+):** Override this method to receive a complete `LogEntry`.
  ///
  /// **Legacy implementations:** Override `logMessage()` instead for backward compatibility.
  ///
  /// [entry] - The complete log entry containing message, level, timestamp, context, and event.
  Future<void> log(LogEntry entry) async {
    // Default implementation: delegate to logMessage for backward compatibility
    await logMessage(entry.message, entry.event, entry.context);
  }

  /// Logs an info message or event.
  ///
  /// **New implementations (v1.4.0+):** Override this method to receive a complete `LogEntry`.
  ///
  /// **Legacy implementations:** Override `logMessage()` instead for backward compatibility.
  ///
  /// [entry] - The complete log entry containing message, level, timestamp, context, and event.
  Future<void> info(LogEntry entry) async {
    // Default implementation: delegate to logMessage for backward compatibility
    await logMessage(entry.message, entry.event, entry.context);
  }

  /// Logs an error.
  ///
  /// **New implementations (v1.4.0+):** Override this method to receive a complete `LogEntry`.
  ///
  /// **Legacy implementations:** Override `logError()` instead for backward compatibility.
  ///
  /// [entry] - The complete log entry containing error message, level, timestamp, context, stackTrace, and event.
  Future<void> error(LogEntry entry) async {
    // Default implementation: delegate to logError for backward compatibility
    await logError(entry.message, entry.stackTrace, entry.event, entry.context);
  }

  /// Logs a fatal error.
  ///
  /// **New implementations (v1.4.0+):** Override this method to receive a complete `LogEntry`.
  ///
  /// **Legacy implementations:** Override `logError()` instead for backward compatibility.
  ///
  /// [entry] - The complete log entry containing fatal error message, level, timestamp, context, stackTrace, and event.
  Future<void> fatal(LogEntry entry) async {
    // Default implementation: delegate to logError for backward compatibility
    await logError(entry.message, entry.stackTrace, entry.event, entry.context);
  }

  /// Legacy method for logging messages (for backward compatibility).
  ///
  /// **Legacy implementations:** Override this method to maintain compatibility with older code.
  /// This method now receives `context` automatically, even if your strategy was written before v1.4.0.
  ///
  /// **New implementations:** Override `log()` and `info()` instead.
  ///
  /// [message] - The message to log.
  /// [event] - Optional. The specific log event associated with the message.
  /// [context] - Optional. Additional context data (now available automatically!).
  Future<void> logMessage(
    dynamic message,
    LogEvent? event,
    Map<String, dynamic>? context,
  ) async {
    // Default: empty implementation
    // Legacy strategies should override this method
  }

  /// Legacy method for logging errors (for backward compatibility).
  ///
  /// **Legacy implementations:** Override this method to maintain compatibility with older code.
  /// This method now receives `context` automatically, even if your strategy was written before v1.4.0.
  ///
  /// **New implementations:** Override `error()` and `fatal()` instead.
  ///
  /// [error] - The error to log.
  /// [stackTrace] - Optional. The stack trace associated with the error.
  /// [event] - Optional. The specific log event associated with the error.
  /// [context] - Optional. Additional context data (now available automatically!).
  Future<void> logError(
    dynamic error,
    StackTrace? stackTrace,
    LogEvent? event,
    Map<String, dynamic>? context,
  ) async {
    // Default: empty implementation
    // Legacy strategies should override this method
  }

  /// Provides a string representation of the strategy including its type and log level.
  @override
  String toString() {
    return '$runtimeType(LogLevel: $logLevel)';
  }
}
