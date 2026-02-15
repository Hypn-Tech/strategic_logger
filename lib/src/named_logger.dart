import 'events/log_event.dart';
import 'strategic_logger.dart';

/// A named logger that automatically includes a logger name in the context.
///
/// Named loggers are useful for organizing logs by module or component.
/// The logger name is injected into the context as `_loggerName` and
/// displayed as a prefix in console output.
///
/// Example:
/// ```dart
/// final authLogger = logger.named('auth');
/// final paymentLogger = logger.named('payment');
///
/// authLogger.info('User logged in');      // context: {_loggerName: 'auth'}
/// paymentLogger.error('Payment failed');  // context: {_loggerName: 'payment'}
/// ```
class NamedLogger {
  final StrategicLogger _logger;

  /// The name of this logger instance.
  final String name;

  /// Creates a named logger that delegates to [_logger] with [name] injected into context.
  NamedLogger(this._logger, this.name);

  Map<String, Object> _mergeContext(Map<String, Object>? context) {
    return {...?context, '_loggerName': name};
  }

  /// Logs a message with this logger's name in context.
  void log(dynamic message, {LogEvent? event, Map<String, Object>? context}) {
    _logger.log(message, event: event, context: _mergeContext(context));
  }

  /// Logs an info message with this logger's name in context.
  void info(dynamic message, {LogEvent? event, Map<String, Object>? context}) {
    _logger.info(message, event: event, context: _mergeContext(context));
  }

  /// Logs a debug message with this logger's name in context.
  void debug(dynamic message, {LogEvent? event, Map<String, Object>? context}) {
    _logger.debug(message, event: event, context: _mergeContext(context));
  }

  /// Logs a warning message with this logger's name in context.
  void warning(
    dynamic message, {
    LogEvent? event,
    Map<String, Object>? context,
  }) {
    _logger.warning(message, event: event, context: _mergeContext(context));
  }

  /// Logs an error with this logger's name in context.
  void error(
    dynamic error, {
    StackTrace? stackTrace,
    LogEvent? event,
    Map<String, Object>? context,
  }) {
    _logger.error(
      error,
      stackTrace: stackTrace,
      event: event,
      context: _mergeContext(context),
    );
  }

  /// Logs a fatal error with this logger's name in context.
  void fatal(
    dynamic error, {
    StackTrace? stackTrace,
    LogEvent? event,
    Map<String, Object>? context,
  }) {
    _logger.fatal(
      error,
      stackTrace: stackTrace,
      event: event,
      context: _mergeContext(context),
    );
  }

  /// Logs a verbose message (alias for debug) with this logger's name in context.
  void verbose(
    dynamic message, {
    LogEvent? event,
    Map<String, Object>? context,
  }) {
    _logger.verbose(message, event: event, context: _mergeContext(context));
  }
}
