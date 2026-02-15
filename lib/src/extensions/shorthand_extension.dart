import '../strategic_logger.dart';

/// Shorthand aliases for common logging methods.
///
/// Provides single-letter convenience methods inspired by the `logger` package.
/// Import `package:strategic_logger/logger.dart` to use these automatically.
///
/// Example:
/// ```dart
/// logger.d('Debug message');
/// logger.i('Info message');
/// logger.w('Warning message');
/// logger.e('Error occurred', stackTrace: StackTrace.current);
/// logger.f('Fatal crash', stackTrace: StackTrace.current);
/// ```
extension StrategicLoggerShorthand on StrategicLogger {
  /// Shorthand for [debug]. Logs a debug message.
  void d(dynamic msg, {Map<String, Object>? context}) =>
      debug(msg, context: context);

  /// Shorthand for [info]. Logs an info message.
  void i(dynamic msg, {Map<String, Object>? context}) =>
      info(msg, context: context);

  /// Shorthand for [warning]. Logs a warning message.
  void w(dynamic msg, {Map<String, Object>? context}) =>
      warning(msg, context: context);

  /// Shorthand for [error]. Logs an error.
  void e(dynamic msg, {StackTrace? stackTrace, Map<String, Object>? context}) =>
      error(msg, stackTrace: stackTrace, context: context);

  /// Shorthand for [fatal]. Logs a fatal error.
  void f(dynamic msg, {StackTrace? stackTrace, Map<String, Object>? context}) =>
      fatal(msg, stackTrace: stackTrace, context: context);
}
