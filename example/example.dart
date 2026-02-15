// Example demonstrating Strategic Logger v4.0.0 features.
//
// This example uses only ConsoleLogStrategy (no external dependencies).
// For Firebase, Sentry, Datadog, or New Relic integration, see the README.
import 'package:strategic_logger/logger.dart';

void main() async {
  // 1. Zero-config: works immediately without initialize()
  logger.info('App started - no setup needed!');

  // 2. Full configuration (recommended for production)
  await logger.initialize(
    projectName: 'EXAMPLE APP',
    level: LogLevel.debug,
    strategies: [
      ConsoleLogStrategy(
        useModernFormatting: true,
        useColors: true,
        showTimestamp: true,
        showContext: true,
      ),
    ],
  );

  // 3. Basic logging
  logger.debug('Debug message');
  logger.info('Info message');
  logger.warning('Warning message');
  logger.error('Error message', stackTrace: StackTrace.current);
  logger.fatal('Fatal error');

  // 4. Shorthand aliases
  logger.d('Debug shorthand');
  logger.i('Info shorthand');
  logger.w('Warning shorthand');

  // 5. Context propagation
  logger.info(
    'User action',
    context: {
      'userId': '123',
      'action': 'login',
      'timestamp': DateTime.now().toIso8601String(),
    },
  );

  // 6. Named loggers
  final authLogger = logger.named('auth');
  final paymentLogger = logger.named('payment');

  authLogger.info('User logged in');
  paymentLogger.error('Payment failed');

  // 7. Lazy evaluation
  logger.debug(() => 'Expensive: ${DateTime.now().microsecondsSinceEpoch}');

  // 8. Structured logging with events
  logger.log(
    'Purchase completed',
    event: LogEvent(
      eventName: 'PURCHASE_COMPLETED',
      parameters: {'amount': '99.99', 'currency': 'USD'},
    ),
  );

  // 9. Stream listener
  final subscription = logger.listen((entry) {
    // Custom processing for each log entry
    print('Listener received: ${entry.level} - ${entry.message}');
  });

  logger.info('This will also trigger the listener');

  // Cleanup
  subscription.cancel();

  print('Example completed!');
}
