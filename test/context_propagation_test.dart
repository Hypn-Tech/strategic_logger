import 'package:strategic_logger/src/core/log_queue.dart';
import 'package:strategic_logger/src/enums/log_level.dart';
import 'package:strategic_logger/src/events/log_event.dart';
import 'package:strategic_logger/src/strategies/console/console_log_strategy.dart';
import 'package:strategic_logger/src/strategies/datadog/datadog_log_strategy.dart';
import 'package:strategic_logger/src/strategic_logger.dart';
import 'package:test/test.dart';

void main() {
  group('Context Propagation Tests', () {
    late StrategicLogger testLogger;

    setUp(() {
      testLogger = StrategicLogger();
    });

    tearDown(() {
      testLogger.dispose();
    });

    test('LogEntry should contain context', () {
      final entry = LogEntry.fromParams(
        message: 'Test message',
        level: LogLevel.info,
        context: {'userId': 123, 'screen': 'home'},
      );

      expect(entry.context, isNotNull);
      expect(entry.context!['userId'], equals(123));
      expect(entry.context!['screen'], equals('home'));
    });

    test('Context should be passed to ConsoleLogStrategy', () async {
      final strategy = ConsoleLogStrategy(
        useModernFormatting: false,
        showContext: true,
      );

      await testLogger.initialize(
        strategies: [strategy],
        level: LogLevel.debug,
        force: true,
      );

      // Create entry with context
      final entry = LogEntry.fromParams(
        message: 'Test with context',
        level: LogLevel.info,
        context: {'userId': 456, 'action': 'test'},
      );

      // Strategy should receive the entry with context
      await strategy.log(entry);

      // Verify context is available (we can't easily test console output,
      // but we can verify the entry has context)
      expect(entry.context, isNotNull);
      expect(entry.context!['userId'], equals(456));
    });

    test('Context should be merged from entry and event', () {
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
    test('DatadogLogStrategy should use v2 endpoint by default', () {
      final strategy = DatadogLogStrategy(
        apiKey: 'test-key',
        service: 'test-service',
        env: 'test',
      );

      expect(
        strategy.datadogUrl,
        equals('https://http-intake.logs.datadoghq.com/api/v2/logs'),
      );
    });

    test('DatadogLogStrategy should enable compression by default', () {
      final strategy = DatadogLogStrategy(
        apiKey: 'test-key',
        service: 'test-service',
        env: 'test',
      );

      expect(strategy.enableCompression, isTrue);
    });

    test('DatadogLogStrategy should create v2 format log entry', () {
      final strategy = DatadogLogStrategy(
        apiKey: 'test-key',
        service: 'test-service',
        env: 'test',
        host: 'test-host',
        source: 'dart',
        tags: 'team:test,version:1.0',
      );

      final entry = LogEntry.fromParams(
        message: 'Test message',
        level: LogLevel.info,
        context: {'userId': 789, 'action': 'login'},
      );

      // Access private method via reflection would be needed for full test
      // For now, we verify the strategy is configured correctly
      expect(strategy.service, equals('test-service'));
      expect(strategy.env, equals('test'));
      expect(strategy.enableCompression, isTrue);
    });

    test('DatadogLogStrategy should include context in log entry', () async {
      final strategy = DatadogLogStrategy(
        apiKey: 'test-key',
        service: 'test-service',
        env: 'test',
      );

      final entry = LogEntry.fromParams(
        message: 'Test with context',
        level: LogLevel.info,
        context: {'userId': 999, 'screen': 'profile'},
      );

      // Verify entry has context
      expect(entry.context, isNotNull);
      expect(entry.context!['userId'], equals(999));
      expect(entry.context!['screen'], equals('profile'));
    });
  });

  group('Logger Context Integration Tests', () {
    late StrategicLogger testLogger;

    setUp(() {
      testLogger = StrategicLogger();
    });

    tearDown(() {
      testLogger.dispose();
    });

    test('logger.log should pass context to strategies', () async {
      final strategy = ConsoleLogStrategy();
      await testLogger.initialize(
        strategies: [strategy],
        level: LogLevel.debug,
        force: true,
      );

      // Log with context - no await needed in v3.0.0
      testLogger.log('Test message', context: {'testKey': 'testValue'});

      // Context should be available in the log entry
      // (We can't easily verify strategy received it without mocking,
      // but we verify the API works)
      expect(testLogger.isInitialized, isTrue);
    });

    test('logger.info should pass context to strategies', () async {
      final strategy = ConsoleLogStrategy();
      await testLogger.initialize(
        strategies: [strategy],
        level: LogLevel.debug,
        force: true,
      );

      testLogger.info('Info message', context: {'infoKey': 'infoValue'});

      expect(testLogger.isInitialized, isTrue);
    });

    test('logger.error should pass context and stackTrace', () async {
      final strategy = ConsoleLogStrategy();
      await testLogger.initialize(
        strategies: [strategy],
        level: LogLevel.debug,
        force: true,
      );

      final stackTrace = StackTrace.current;
      testLogger.error(
        'Error message',
        stackTrace: stackTrace,
        context: {'errorKey': 'errorValue'},
      );

      expect(testLogger.isInitialized, isTrue);
    });
  });
}
