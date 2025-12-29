/// Example: Legacy Strategy (v1.3.0 style) - Still Works in v1.4.0!
///
/// This example demonstrates that old custom strategies continue to work
/// without any modifications, and now automatically receive context.
///
/// No code changes needed - context is now available automatically!

import 'package:strategic_logger/logger.dart';

/// Legacy strategy written for v1.3.0 - still works in v1.4.0!
///
/// This strategy uses the old `logMessage()` and `logError()` methods.
/// In v1.4.0, these methods now receive context automatically!
class MyLegacyStrategy extends LogStrategy {
  MyLegacyStrategy({super.logLevel = LogLevel.info});

  /// Legacy method - still works! Now receives context automatically.
  @override
  Future<void> logMessage(
    dynamic message,
    LogEvent? event,
    Map<String, dynamic>? context, // ← Context is now available!
  ) async {
    print('📝 [LEGACY] Message: $message');

    // Context is now available automatically! 🎉
    if (context != null && context.isNotEmpty) {
      print('📝 [LEGACY] Context: $context');
    }

    if (event != null) {
      print('📝 [LEGACY] Event: ${event.eventName}');
    }
  }

  /// Legacy method - still works! Now receives context automatically.
  @override
  Future<void> logError(
    dynamic error,
    StackTrace? stackTrace,
    LogEvent? event,
    Map<String, dynamic>? context, // ← Context is now available!
  ) async {
    print('❌ [LEGACY] Error: $error');

    // Context is now available automatically! 🎉
    if (context != null && context.isNotEmpty) {
      print('❌ [LEGACY] Context: $context');
    }

    if (stackTrace != null) {
      print('❌ [LEGACY] StackTrace: $stackTrace');
    }
  }
}

/// Example usage
void main() async {
  // Initialize logger with legacy strategy
  await logger.initialize(
    strategies: [MyLegacyStrategy(), ConsoleLogStrategy()],
    level: LogLevel.debug,
  );

  // Log with context - legacy strategy receives it automatically!
  await logger.log(
    'Test message',
    context: {'userId': 123, 'screen': 'home', 'action': 'button_click'},
  );

  // Error with context - legacy strategy receives it automatically!
  await logger.error(
    'Test error',
    stackTrace: StackTrace.current,
    context: {'errorCode': 500, 'endpoint': '/api/users'},
  );
}

