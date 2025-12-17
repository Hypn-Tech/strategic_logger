import 'package:test/test.dart';
import 'package:strategic_logger/logger.dart';

/// Test suite to verify that context is properly passed to strategies
void main() {
  group('Context Passing to Strategies', () {
    late TestLogStrategy testStrategy;

    setUp(() async {
      testStrategy = TestLogStrategy();
      await logger.initialize(
        level: LogLevel.debug,
        strategies: [testStrategy],
        useIsolates: false, // Disable isolates for simpler testing
        enablePerformanceMonitoring: false,
      );
    });

    tearDown(() {
      logger.dispose();
    });

    test('Context should be passed to strategy log method', () async {
      final testContext = {'userId': '123', 'action': 'test_action'};
      
      await logger.log('Test message', context: testContext);
      
      // Give logger time to process
      await Future.delayed(Duration(milliseconds: 100));
      
      expect(testStrategy.lastContext, isNotNull);
      expect(testStrategy.lastContext!['userId'], equals('123'));
      expect(testStrategy.lastContext!['action'], equals('test_action'));
    });

    test('Context should be passed to strategy info method', () async {
      final testContext = {'userId': '456', 'sessionId': 'abc123'};
      
      await logger.info('Info message', context: testContext);
      
      // Give logger time to process
      await Future.delayed(Duration(milliseconds: 100));
      
      expect(testStrategy.lastContext, isNotNull);
      expect(testStrategy.lastContext!['userId'], equals('456'));
      expect(testStrategy.lastContext!['sessionId'], equals('abc123'));
    });

    test('Context should be passed to strategy error method', () async {
      final testContext = {
        'errorCode': '500',
        'endpoint': '/api/test',
        'requestId': 'req123'
      };
      
      await logger.error(
        'Test error',
        context: testContext,
        stackTrace: StackTrace.current,
      );
      
      // Give logger time to process
      await Future.delayed(Duration(milliseconds: 100));
      
      expect(testStrategy.lastContext, isNotNull);
      expect(testStrategy.lastContext!['errorCode'], equals('500'));
      expect(testStrategy.lastContext!['endpoint'], equals('/api/test'));
      expect(testStrategy.lastContext!['requestId'], equals('req123'));
    });

    test('Context should be passed to strategy fatal method', () async {
      final testContext = {
        'criticalError': true,
        'systemState': 'crashed',
        'timestamp': DateTime.now().toIso8601String()
      };
      
      await logger.fatal(
        'Fatal error',
        context: testContext,
        stackTrace: StackTrace.current,
      );
      
      // Give logger time to process
      await Future.delayed(Duration(milliseconds: 100));
      
      expect(testStrategy.lastContext, isNotNull);
      expect(testStrategy.lastContext!['criticalError'], equals(true));
      expect(testStrategy.lastContext!['systemState'], equals('crashed'));
    });

    test('Context should be passed to strategy debug method', () async {
      final testContext = {'debugFlag': true, 'module': 'test_module'};
      
      await logger.debug('Debug message', context: testContext);
      
      // Give logger time to process
      await Future.delayed(Duration(milliseconds: 100));
      
      expect(testStrategy.lastContext, isNotNull);
      expect(testStrategy.lastContext!['debugFlag'], equals(true));
      expect(testStrategy.lastContext!['module'], equals('test_module'));
    });

    test('Context should be passed to strategy warning method', () async {
      final testContext = {
        'warningLevel': 'medium',
        'source': 'api_rate_limit'
      };
      
      await logger.warning('Warning message', context: testContext);
      
      // Give logger time to process
      await Future.delayed(Duration(milliseconds: 100));
      
      expect(testStrategy.lastContext, isNotNull);
      expect(testStrategy.lastContext!['warningLevel'], equals('medium'));
      expect(testStrategy.lastContext!['source'], equals('api_rate_limit'));
    });

    test('Context should work with event parameters', () async {
      final testContext = {'contextKey': 'contextValue'};
      final testEvent = LogEvent(
        eventName: 'TEST_EVENT',
        eventMessage: 'Test event message',
        parameters: {'eventKey': 'eventValue'},
      );
      
      await logger.log('Test message', context: testContext, event: testEvent);
      
      // Give logger time to process
      await Future.delayed(Duration(milliseconds: 100));
      
      // Both context and event should be passed
      expect(testStrategy.lastContext, isNotNull);
      expect(testStrategy.lastContext!['contextKey'], equals('contextValue'));
      expect(testStrategy.lastEvent, isNotNull);
      expect(testStrategy.lastEvent!.eventName, equals('TEST_EVENT'));
    });

    test('Empty context should not cause errors', () async {
      await logger.log('Test message', context: {});
      
      // Give logger time to process
      await Future.delayed(Duration(milliseconds: 100));
      
      // Should work fine with empty context
      expect(testStrategy.callCount, greaterThan(0));
    });

    test('Null context should not cause errors', () async {
      await logger.log('Test message', context: null);
      
      // Give logger time to process
      await Future.delayed(Duration(milliseconds: 100));
      
      // Should work fine with null context
      expect(testStrategy.callCount, greaterThan(0));
    });
  });
}

/// A test strategy that captures the last context passed to it
class TestLogStrategy extends LogStrategy {
  Map<String, dynamic>? lastContext;
  LogEvent? lastEvent;
  dynamic lastMessage;
  int callCount = 0;

  TestLogStrategy() : super(logLevel: LogLevel.debug);

  @override
  Future<void> log({
    dynamic message,
    LogEvent? event,
    Map<String, dynamic>? context,
  }) async {
    callCount++;
    lastMessage = message;
    lastEvent = event;
    lastContext = context;
  }

  @override
  Future<void> info({
    dynamic message,
    LogEvent? event,
    Map<String, dynamic>? context,
  }) async {
    callCount++;
    lastMessage = message;
    lastEvent = event;
    lastContext = context;
  }

  @override
  Future<void> error({
    dynamic error,
    StackTrace? stackTrace,
    LogEvent? event,
    Map<String, dynamic>? context,
  }) async {
    callCount++;
    lastMessage = error;
    lastEvent = event;
    lastContext = context;
  }

  @override
  Future<void> fatal({
    dynamic error,
    StackTrace? stackTrace,
    LogEvent? event,
    Map<String, dynamic>? context,
  }) async {
    callCount++;
    lastMessage = error;
    lastEvent = event;
    lastContext = context;
  }
}
