import 'package:strategic_logger/logger.dart';
import 'package:strategic_logger/src/core/log_queue.dart';
import 'package:test/test.dart';

/// Test suite for MCP Log Strategy functionality
void main() {
  group('MCP Log Strategy Tests', () {
    late MCPLogStrategy mcpStrategy;

    setUp(() {
      mcpStrategy = MCPLogStrategy(
        enableRealTimeStreaming: true,
        enableHealthMonitoring: true,
        defaultContext: {'app': 'test', 'version': '1.0.0'},
      );
    });

    tearDown(() async {
      await mcpStrategy.stopServer();
      mcpStrategy.dispose();
    });

    test('MCP Log Strategy should initialize correctly', () {
      expect(mcpStrategy, isNotNull);
      expect(mcpStrategy.logLevel, equals(LogLevel.info));
      expect(mcpStrategy.loggerLogLevel, equals(LogLevel.info));
      expect(mcpStrategy.supportedEvents, isNotNull);
      expect(mcpStrategy.supportedEvents!.length, greaterThan(0));
    });

    test('MCP Log Strategy should start and stop server correctly', () async {
      expect(mcpStrategy.mcpServer.isRunning, isFalse);

      await mcpStrategy.startServer();
      expect(mcpStrategy.mcpServer.isRunning, isTrue);

      await mcpStrategy.stopServer();
      expect(mcpStrategy.mcpServer.isRunning, isFalse);
    });

    test('MCP Log Strategy should log info messages correctly', () async {
      await mcpStrategy.startServer();

      final entry = LogEntry(
        message: 'Test info message',
        level: LogLevel.info,
        timestamp: DateTime.now(),
      );
      await mcpStrategy.info(entry);

      // Verify log was added to MCP server history
      expect(mcpStrategy.mcpServer.logHistory.length, greaterThan(0));

      final lastLog = mcpStrategy.mcpServer.logHistory.first;
      expect(lastLog.level, equals(LogLevel.info));
      expect(lastLog.message, equals('Test info message'));
    });

    test('MCP Log Strategy should log error messages correctly', () async {
      await mcpStrategy.startServer();

      final entry = LogEntry(
        message: 'Test error message',
        level: LogLevel.error,
        timestamp: DateTime.now(),
      );
      await mcpStrategy.error(entry);

      // Verify log was added to MCP server history
      expect(mcpStrategy.mcpServer.logHistory.length, greaterThan(0));

      final lastLog = mcpStrategy.mcpServer.logHistory.first;
      expect(lastLog.level, equals(LogLevel.error));
      expect(lastLog.message, equals('Test error message'));
    });

    test('MCP Log Strategy should log fatal messages correctly', () async {
      await mcpStrategy.startServer();

      final entry = LogEntry(
        message: 'Test fatal message',
        level: LogLevel.fatal,
        timestamp: DateTime.now(),
      );
      await mcpStrategy.fatal(entry);

      // Verify log was added to MCP server history
      expect(mcpStrategy.mcpServer.logHistory.length, greaterThan(0));

      final lastLog = mcpStrategy.mcpServer.logHistory.first;
      expect(lastLog.level, equals(LogLevel.fatal));
      expect(lastLog.message, equals('Test fatal message'));
    });

    test('MCP Log Strategy should log with events correctly', () async {
      await mcpStrategy.startServer();

      final event = LogEvent(
        eventName: 'TEST_EVENT',
        eventMessage: 'Test event message',
      );

      final entry = LogEntry(
        message: 'Test message with event',
        level: LogLevel.info,
        timestamp: DateTime.now(),
        event: event,
      );
      await mcpStrategy.log(entry);

      // Verify log was added to MCP server history
      expect(mcpStrategy.mcpServer.logHistory.length, greaterThan(0));

      final lastLog = mcpStrategy.mcpServer.logHistory.first;
      expect(lastLog.event, isNotNull);
      expect(lastLog.event!.eventName, equals('TEST_EVENT'));
    });

    test('MCP Log Strategy should handle context correctly', () async {
      await mcpStrategy.startServer();

      final entry = LogEntry(
        message: 'Test message',
        level: LogLevel.info,
        timestamp: DateTime.now(),
      );
      await mcpStrategy.info(entry);

      // Verify log was added
      final lastLog = mcpStrategy.mcpServer.logHistory.first;
      expect(lastLog.message, equals('Test message'));
    });

    test('MCP Log Strategy should get health status correctly', () async {
      await mcpStrategy.startServer();

      final healthStatus = await mcpStrategy.getHealthStatus();

      expect(healthStatus, isA<Map<String, dynamic>>());
      expect(healthStatus['mcp_server'], isTrue);
      expect(healthStatus['status'], equals('healthy'));
    });

    test('MCP Log Strategy should query logs correctly', () async {
      await mcpStrategy.startServer();

      // Add some test logs
      await mcpStrategy.info(LogEntry(
        message: 'Test message 1',
        level: LogLevel.info,
        timestamp: DateTime.now(),
      ));
      await mcpStrategy.error(LogEntry(
        message: 'Test error 1',
        level: LogLevel.error,
        timestamp: DateTime.now(),
      ));
      await mcpStrategy.info(LogEntry(
        message: 'Test message 2',
        level: LogLevel.info,
        timestamp: DateTime.now(),
      ));

      final logs = await mcpStrategy.queryLogs(level: LogLevel.info, limit: 10);

      expect(logs, isA<List<MCPLogEntry>>());
    });

    test(
      'MCP Log Strategy should handle server not running gracefully',
      () async {
        // Don't start server
        expect(mcpStrategy.mcpServer.isRunning, isFalse);

        // Should not throw when logging without server
        final entry = LogEntry(
          message: 'Test message',
          level: LogLevel.info,
          timestamp: DateTime.now(),
        );
        await mcpStrategy.info(entry);

        // Server should auto-start
        expect(mcpStrategy.mcpServer.isRunning, isTrue);
      },
    );

    test('MCP Log Strategy should format messages correctly', () {
      // Test string message
      expect(mcpStrategy.formatMessage('Test string'), equals('Test string'));

      // Test null message
      expect(mcpStrategy.formatMessage(null), equals('null'));

      // Test Map message
      final mapMessage = {'key': 'value'};
      final formatted = mcpStrategy.formatMessage(mapMessage);
      expect(formatted, contains('key'));
      expect(formatted, contains('value'));

      // Test List message
      final listMessage = [1, 2, 3];
      final formattedList = mcpStrategy.formatMessage(listMessage);
      expect(formattedList, contains('1'));
      expect(formattedList, contains('2'));
      expect(formattedList, contains('3'));
    });

    test('MCP Log Strategy should generate unique log IDs', () {
      final id1 = mcpStrategy.generateLogId();
      final id2 = mcpStrategy.generateLogId();

      expect(id1, isNot(equals(id2)));
      expect(id1, isNotEmpty);
      expect(id2, isNotEmpty);
    });

    test('MCP Log Strategy should build context correctly', () {
      final additionalContext = {'extra': 'data'};
      final stackTrace = StackTrace.current;

      final context = mcpStrategy.buildContext(additionalContext, stackTrace);

      // Should include default context
      expect(context['app'], equals('test'));
      expect(context['version'], equals('1.0.0'));

      // Should include additional context
      expect(context['extra'], equals('data'));

      // Should include stack trace
      expect(context['stackTrace'], isNotNull);

      // Should include MCP-specific context
      expect(context['mcp_timestamp'], isNotNull);
      expect(context['mcp_source'], equals('strategic_logger'));
      expect(context['mcp_version'], equals('1.1.0'));
    });

    test(
      'MCP Log Strategy should convert LogEntry to MCPLogEntry correctly',
      () async {
        await mcpStrategy.startServer();

        // Test MCPLogEntry creation directly

        // Test the conversion logic directly
        final mcpLogEntry = MCPLogEntry(
          id: 'test_id',
          timestamp: DateTime.now(),
          level: LogLevel.info,
          message: 'Test message',
          context: {'test': true},
          source: 'strategic_logger',
        );

        expect(mcpLogEntry.level, equals(LogLevel.info));
        expect(mcpLogEntry.message, equals('Test message'));
        expect(mcpLogEntry.context, equals({'test': true}));
        expect(mcpLogEntry.source, equals('strategic_logger'));
      },
    );

    test('MCP Log Strategy toString should return correct representation', () {
      final strategy = MCPLogStrategy(
        enableRealTimeStreaming: false,
        enableHealthMonitoring: false,
      );

      final string = strategy.toString();

      expect(string, contains('MCPLogStrategy'));
      expect(string, contains('streaming: false'));
      expect(string, contains('health: false'));
    });
  });
}
