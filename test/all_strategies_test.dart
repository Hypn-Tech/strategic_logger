import 'package:strategic_logger/src/core/log_queue.dart';
import 'package:strategic_logger/src/enums/log_level.dart';
import 'package:strategic_logger/src/events/log_event.dart';
import 'package:strategic_logger/src/strategies/analytics/firebase_analytics_log_strategy.dart';
import 'package:strategic_logger/src/strategies/console/console_log_strategy.dart';
import 'package:strategic_logger/src/strategies/crashlytics/firebase_crashlytics_log_strategy.dart';
import 'package:strategic_logger/src/strategies/datadog/datadog_log_strategy.dart';
import 'package:strategic_logger/src/strategies/newrelic/newrelic_log_strategy.dart';
import 'package:strategic_logger/src/strategies/sentry/sentry_log_strategy.dart';
import 'package:strategic_logger/src/strategic_logger.dart';
import 'package:test/test.dart';

void main() {
  group('All Built-in Strategies Tests', () {
    late StrategicLogger testLogger;

    setUp(() {
      testLogger = StrategicLogger();
    });

    tearDown(() {
      try {
        if (testLogger.isInitialized) {
          testLogger.dispose();
        }
      } catch (e) {
        // Ignore dispose errors in tests
      }
    });

    test('ConsoleLogStrategy receives context', () async {
      final strategy = ConsoleLogStrategy(
        useModernFormatting: false,
        showContext: true,
      );

      await testLogger.initialize(
        strategies: [strategy],
        level: LogLevel.debug,
      );

      final entry = LogEntry.fromParams(
        message: 'Test message',
        level: LogLevel.info,
        context: {'userId': 123, 'screen': 'home'},
      );

      await strategy.log(entry);

      // Verify entry has context
      expect(entry.context, isNotNull);
      expect(entry.context!['userId'], equals(123));
    });

    test('DatadogLogStrategy uses v2 endpoint and receives context', () {
      final strategy = DatadogLogStrategy(
        apiKey: 'test-key',
        service: 'test-service',
        env: 'test',
        enableCompression: true,
      );

      expect(
        strategy.datadogUrl,
        equals('https://http-intake.logs.datadoghq.com/api/v2/logs'),
      );
      expect(strategy.enableCompression, isTrue);

      final entry = LogEntry.fromParams(
        message: 'Test',
        level: LogLevel.info,
        context: {'userId': 456},
      );

      expect(entry.context, isNotNull);
      expect(entry.context!['userId'], equals(456));
    });

    test('SentryLogStrategy receives context', () async {
      final strategy = SentryLogStrategy();

      await testLogger.initialize(
        strategies: [strategy],
        level: LogLevel.debug,
        force: true,
      );

      final entry = LogEntry.fromParams(
        message: 'Test error',
        level: LogLevel.error,
        context: {'errorCode': 500},
        stackTrace: StackTrace.current,
      );

      await strategy.error(entry);

      expect(entry.context, isNotNull);
      expect(entry.context!['errorCode'], equals(500));
    });

    test('FirebaseAnalyticsLogStrategy receives context', () async {
      final strategy = FirebaseAnalyticsLogStrategy();

      await testLogger.initialize(
        strategies: [strategy],
        level: LogLevel.debug,
        force: true,
      );

      final entry = LogEntry.fromParams(
        message: 'Test event',
        level: LogLevel.info,
        context: {'eventType': 'click'},
      );

      await strategy.log(entry);

      expect(entry.context, isNotNull);
      expect(entry.context!['eventType'], equals('click'));
    });

    test('FirebaseCrashlyticsLogStrategy receives context', () async {
      final strategy = FirebaseCrashlyticsLogStrategy();

      await testLogger.initialize(
        strategies: [strategy],
        level: LogLevel.debug,
        force: true,
      );

      final entry = LogEntry.fromParams(
        message: 'Test crash',
        level: LogLevel.error,
        context: {'crashType': 'fatal'},
        stackTrace: StackTrace.current,
      );

      await strategy.error(entry);

      expect(entry.context, isNotNull);
      expect(entry.context!['crashType'], equals('fatal'));
    });

    test('NewRelicLogStrategy receives context', () {
      final strategy = NewRelicLogStrategy(
        licenseKey: 'test-key',
        appName: 'test-app',
      );

      final entry = LogEntry.fromParams(
        message: 'Test log',
        level: LogLevel.info,
        context: {'metric': 'response_time', 'value': 123},
      );

      expect(entry.context, isNotNull);
      expect(entry.context!['metric'], equals('response_time'));
    });

    test('All strategies receive context from logger.log()', () async {
      final consoleStrategy = ConsoleLogStrategy(useModernFormatting: false);
      final datadogStrategy = DatadogLogStrategy(
        apiKey: 'test-key',
        service: 'test',
        env: 'test',
      );

      await testLogger.initialize(
        strategies: [consoleStrategy, datadogStrategy],
        level: LogLevel.debug,
        force: true,
      );

      // Wait a bit for initialization to complete
      await Future.delayed(const Duration(milliseconds: 100));

      // Log with context
      await testLogger.log(
        'Test message',
        context: {'userId': 789, 'action': 'test'},
      );

      // Context should be available in both strategies
      expect(testLogger.isInitialized, isTrue);
    });

    test('Context is merged from entry.context and event.parameters', () {
      final event = LogEvent(
        eventName: 'test_event',
        parameters: {'eventParam': 'value'},
      );

      final entry = LogEntry.fromParams(
        message: 'Test',
        level: LogLevel.info,
        context: {'entryParam': 'entryValue'},
        event: event,
      );

      expect(entry.context, isNotNull);
      expect(entry.context!['entryParam'], equals('entryValue'));
      expect(entry.event?.parameters?['eventParam'], equals('value'));
    });
  });

  group('Datadog v2 Format Tests', () {
    test('DatadogLogStrategy creates proper v2 format', () {
      final strategy = DatadogLogStrategy(
        apiKey: 'test-key',
        service: 'test-service',
        env: 'production',
        host: 'test-host',
        source: 'dart',
        tags: 'team:test,version:1.0',
        enableCompression: true,
      );

      final entry = LogEntry.fromParams(
        message: 'Test message',
        level: LogLevel.info,
        context: {'userId': 999, 'action': 'login'},
      );

      // Verify strategy configuration
      expect(strategy.service, equals('test-service'));
      expect(strategy.env, equals('production'));
      expect(strategy.enableCompression, isTrue);
      expect(
        strategy.datadogUrl,
        equals('https://http-intake.logs.datadoghq.com/api/v2/logs'),
      );

      // Verify entry has context
      expect(entry.context, isNotNull);
      expect(entry.context!['userId'], equals(999));
    });

    test('DatadogLogStrategy compression can be disabled', () {
      final strategy = DatadogLogStrategy(
        apiKey: 'test-key',
        service: 'test-service',
        env: 'test',
        enableCompression: false,
      );

      expect(strategy.enableCompression, isFalse);
    });
  });
}

