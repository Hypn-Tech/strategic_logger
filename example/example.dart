import 'package:strategic_logger/logger.dart';

/// Example demonstrating Strategic Logger v3.0.0 features.
///
/// This example shows:
/// - Auto-initialization (works without calling initialize()!)
/// - Synchronous logging API (no await needed!)
/// - Dynamic project name banner (displayed in colored ASCII art!)
/// - Modern console formatting with colors
/// - Context propagation to all strategies
/// - Multi-strategy logging (Console, Firebase, Datadog, NewRelic)
void main() async {
  // NEW in v3.0.0: Logger works immediately without initialize()!
  // Auto-initializes with ConsoleLogStrategy at debug level.
  logger.info('This works without initialize()!');
  logger.debug('No await needed either.');

  // For full configuration, call initialize() (optional but recommended for production)
  await logger.initialize(
    projectName: 'EXAMPLE APP', // Your project name in ASCII art!
    level: LogLevel
        .debug, // Define from which log level the logger will be triggered.
    strategies: [
      // Register the log strategies that the logger will call. Some strategies are already implemented for convenience.
      ConsoleLogStrategy(
        useModernFormatting: true,
        useColors: true,
        showTimestamp: true,
        showContext: true,
      ), // ConsoleLogStrategy with modern formatting
      // Other strategies can be implemented by extending LogStrategy and registered here.
    ],
    useIsolates: true, // Enable isolate-based processing
    enablePerformanceMonitoring: true, // Enable performance monitoring
    enableModernConsole: true, // Enable modern console formatting
  );

  // All logging methods are now synchronous (void) - no await needed!
  logger.debug('Debug message with modern formatting');
  logger.info(
    'Info message with context',
    context: {'userId': '123', 'action': 'login'},
  );
  logger.warning(
    'Warning message with event',
    event: LogEvent(eventName: 'WARNING_EVENT'),
  );
  logger.error(
    'Error message with stack trace',
    stackTrace: StackTrace.current,
  );
  logger.fatal('Fatal error message');

  // Structured logging
  logger.logStructured(
    LogLevel.info,
    'User action completed',
    data: {'userId': '123', 'action': 'purchase', 'amount': 99.99},
    tag: 'USER_ACTION',
  );

  // Performance monitoring
  print('Performance Stats: ${logger.getPerformanceStats()}');

  // Reconfiguration of the logger after initialization is not recommended without a strong reason.
  await logger.reconfigure(
    // Example: If you need to reconfigure the logger strategies or update the logLevel after loading environment variables and strategy dependencies, you can reconfigure, but not before using the logger.
    level: LogLevel
        .info, // Define from which log level the logger will be triggered.
    strategies: [
      // Register the log strategies that the logger will call. Some strategies are already implemented for convenience.
      ConsoleLogStrategy(
        useModernFormatting: true,
        useColors: true,
      ), // ConsoleLogStrategy with modern formatting
      FirebaseCrashlyticsLogStrategy(), // FirebaseCrashlyticsLogStrategy logs errors to Crashlytics (This strategy will use your environment configuration).
      FirebaseAnalyticsLogStrategy(), // FirebaseAnalyticsLogStrategy logs events to Firebase Analytics (This strategy will use your environment configuration).
      // New modern strategies
      DatadogLogStrategy(
        apiKey: 'your-datadog-api-key',
        service: 'my-app',
        env: 'production',
        host: 'mobile-app',
        source: 'flutter',
        tags: 'team:mobile,version:1.0.0',
      ), // DatadogLogStrategy for centralized logging

      NewRelicLogStrategy(
        licenseKey: 'your-newrelic-license-key',
        appName: 'my-app',
        host: 'mobile-app',
        environment: 'production',
      ), // NewRelicLogStrategy for application monitoring
      // Other strategies can be implemented by extending LogStrategy and registered here.
    ],
    useIsolates: true,
    enablePerformanceMonitoring: true,
    enableModernConsole: true,
  );

  logger.log(
    'logging',
  ); // Calls the log method of ConsoleLogStrategy(), FirebaseCrashlyticsLogStrategy(), FirebaseAnalyticsLogStrategy() with just the message.
  logger.error(
    'error',
  ); // Calls the error method of ConsoleLogStrategy(), FirebaseCrashlyticsLogStrategy(), FirebaseAnalyticsLogStrategy() with just the error.
  logger.fatal(
    'fatal error',
  ); // Calls the fatal log of ConsoleLogStrategy(), FirebaseCrashlyticsLogStrategy(), FirebaseAnalyticsLogStrategy() with just the fatal error.

  // To send more structured logs, we can send a LogEvent (all strategies will be called).
  logger.log(
    'purchase completed',
    event: ConsoleLogEvent(
      eventName: 'PURCHASE_COMPLETED',
      parameters: {'key': 'value', 'key2': 'value'},
    ),
  );

  // To register a specific event of a strategy, we can specialize the event (only Console Log will be called).
  logger.log(
    'purchase completed',
    event: ConsoleLogEvent(
      eventName: 'PURCHASE_COMPLETED',
      parameters: {'key': 'value', 'key2': 'value'},
    ),
  );

  // To register a specific event of a strategy, we can specialize the event (only Firebase Analytics will be called).
  logger.log(
    'purchase completed',
    event: FirebaseAnalyticsLogEvent(
      eventName: 'PURCHASE_COMPLETED',
      parameters: {'key': 'value', 'key2': 'value'},
    ),
  );

  // To register a specific event of a strategy, we can specialize the event (only Firebase Crashlytics will be called).
  logger.error(
    'non-fatal error',
    event: FirebaseCrashlyticsLogEvent(
      eventName: 'ERROR',
      parameters: {'key': 'value', 'key2': 'value'},
    ),
  );
  logger.fatal(
    'fatal error',
    event: FirebaseAnalyticsLogEvent(
      eventName: 'FATAL_ERROR',
      parameters: {'key': 'value', 'key2': 'value'},
    ),
  );

  // During logger initialization and reconfiguration, we can restrict the events that will be allowed to be logged in each strategy.
  logger.reconfigure(
    // Example: If you need to reconfigure the logger strategies or update the logLevel after loading environment variables and strategy dependencies, you can reconfigure, but not before using the logger.
    level: LogLevel
        .error, // Define from which log level the logger will be triggered.
    strategies: [
      // Register the log strategies that the logger will call. Some strategies are already implemented for convenience.
      ConsoleLogStrategy(
        supportedEvents: [
          ConsoleLogEvent(eventName: 'Event-A'),
          ConsoleLogEvent(eventName: 'Event-B'),
        ],
      ), // The logger will only be triggered for Event-A or Event-B for the ConsoleLog strategy.
      FirebaseAnalyticsLogStrategy(
        supportedEvents: [
          FirebaseAnalyticsLogEvent(eventName: 'Event-C'),
          FirebaseAnalyticsLogEvent(eventName: 'Event-D'),
        ],
      ), // The logger will only be triggered for Event-C or Event-D for the FirebaseAnalyticsLog strategy.
      FirebaseCrashlyticsLogStrategy(
        supportedEvents: [
          FirebaseCrashlyticsLogEvent(eventName: 'FATAL-ERROR-1'),
          FirebaseCrashlyticsLogEvent(eventName: 'FATAL-ERROR-2'),
        ],
      ), // The logger will only be triggered for FATAL-ERROR-1 or FATAL-ERROR-2 for the FirebaseCrashlyticsLog strategy.
      // Other strategies can be implemented by extending LogStrategy and registered here.
    ],
  );

  print('Example completed successfully!');
}
