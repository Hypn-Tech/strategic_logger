import 'dart:developer' as developer;

import '../../console/modern_console_formatter.dart';
import '../../core/isolate_manager.dart';
import '../../core/log_queue.dart';
import '../../enums/log_level.dart';
import '../../events/log_event.dart';
import '../log_strategy.dart';

/// A [LogStrategy] implementation that logs messages, errors, and fatal errors to the console.
///
/// This strategy provides a modern way to output log information directly to the console,
/// suitable for development and troubleshooting purposes. It supports distinguishing between
/// general log messages, errors, and fatal errors, and can handle structured [LogEvent] instances
/// if provided.
///
/// Features:
/// - Modern console formatting with colors and emojis
/// - Isolate-based processing for heavy operations
/// - Performance monitoring
/// - Structured output with context and events
///
/// Example:
/// ```dart
/// var consoleStrategy = ConsoleLogStrategy(logLevel: LogLevel.info);
/// var logger = StrategicLogger(strategies: [consoleStrategy]);
/// logger.log("A simple log message.");
/// ```
class ConsoleLogStrategy extends LogStrategy {
  final bool _useModernFormatting;
  final bool _useColors;
  final bool _showTimestamp;
  final bool _showContext;

  /// Constructs a [ConsoleLogStrategy].
  ///
  /// [logLevel] sets the log level at which this strategy becomes active.
  /// [supportedEvents] optionally specifies which types of [LogEvent] this strategy should handle.
  /// [useModernFormatting] enables modern console formatting with colors and emojis.
  /// [useColors] enables colored output.
  /// [showTimestamp] shows timestamp in logs.
  /// [showContext] shows context information in logs.
  ConsoleLogStrategy({
    super.logLevel = LogLevel.none,
    super.supportedEvents,
    bool useModernFormatting = true,
    bool useColors = true,
    bool showTimestamp = true,
    bool showContext = true,
  }) : _useModernFormatting = useModernFormatting,
       _useColors = useColors,
       _showTimestamp = showTimestamp,
       _showContext = showContext;

  /// Logs a message or a structured event to the console.
  ///
  /// [entry] - The complete log entry containing message, level, timestamp, context, and event.
  @override
  Future<void> log(LogEntry entry) async {
    await _logMessage(entry);
  }

  /// Logs a message or a structured event to the console.
  ///
  /// [entry] - The complete log entry containing message, level, timestamp, context, and event.
  @override
  Future<void> info(LogEntry entry) async {
    await _logMessage(entry);
  }

  /// Logs an error or a structured event with an error to the console.
  ///
  /// [entry] - The complete log entry containing error message, level, timestamp, context, stackTrace, and event.
  @override
  Future<void> error(LogEntry entry) async {
    await _logMessage(entry);
  }

  /// Marks an error as fatal and records it to the console.
  ///
  /// This method treats the error as a critical failure that should be prominently flagged in the console.
  ///
  /// [entry] - The complete log entry containing fatal error message, level, timestamp, context, stackTrace, and event.
  @override
  Future<void> fatal(LogEntry entry) async {
    await _logMessage(entry);
  }

  /// Internal method to log messages with modern formatting
  Future<void> _logMessage(LogEntry entry) async {
    try {
      if (!shouldLog(event: entry.event)) return;

      // Merge context from entry.context and event.parameters
      final mergedContext = <String, dynamic>{};
      if (entry.context != null) {
        mergedContext.addAll(entry.context!);
      }
      if (entry.event?.parameters != null) {
        mergedContext.addAll(entry.event!.parameters!);
      }

      String formattedMessage;

      if (_useModernFormatting) {
        // Use isolate for heavy formatting if available
        try {
          final formatted = await isolateManager.formatLog(
            message: entry.message.toString(),
            level: entry.level.name,
            timestamp: entry.timestamp,
            context: mergedContext.isNotEmpty ? mergedContext : null,
          );
          formattedMessage = formatted['formatted'] as String;
        } catch (e) {
          // Fallback to direct formatting
          // Disable emojis since we're using the formatted header
          formattedMessage = modernConsoleFormatter.formatLog(
            level: entry.level,
            message: entry.message.toString(),
            timestamp: entry.timestamp,
            event: entry.event,
            stackTrace: entry.stackTrace,
            useColors: _useColors,
            useEmojis: false, // Disabled because we have formatted header
            showTimestamp: _showTimestamp,
            showContext: _showContext,
            context: mergedContext.isNotEmpty ? mergedContext : null,
          );
        }
      } else {
        // Legacy formatting
        formattedMessage = _formatLegacyMessage(entry, mergedContext);
      }

      // Add HYPN-TECH header to all logs with visual formatting
      final finalMessage = _formatLogHeader(entry.level, formattedMessage);

      // Output to console (terminal)
      print(finalMessage);

      // Also log to developer console (DevTools)
      developer.log(
        finalMessage,
        name: 'ConsoleLogStrategy',
        error: entry.level == LogLevel.error || entry.level == LogLevel.fatal
            ? entry.message
            : null,
        stackTrace: entry.stackTrace,
      );
    } catch (e, stack) {
      developer.log(
        'Error during logging in ConsoleLogStrategy: $e',
        name: 'ConsoleLogStrategy',
        error: e,
        stackTrace: stack,
      );
    }
  }

  /// Formats the log header with visual styling and colors
  String _formatLogHeader(LogLevel level, String message) {
    if (!_useColors) {
      // Fallback to simple format without colors
      return '[HYPN-TECH][STRATEGIC-LOGGER][${level.name.toUpperCase()}] $message';
    }

    // ANSI color codes
    const String reset = '\x1B[0m';
    const String bold = '\x1B[1m';

    // HYPN-TECH colors (teal/cyan theme)
    const String hypnTechBg = '\x1B[46m'; // Cyan background
    const String hypnTechText = '\x1B[30m'; // Black text on cyan background

    // STRATEGIC-LOGGER colors (blue theme)
    const String strategicLoggerBg = '\x1B[44m'; // Blue background
    const String strategicLoggerText =
        '\x1B[37m'; // White text on blue background

    // Level colors
    String levelBg;
    String levelText;

    switch (level) {
      case LogLevel.debug:
        levelBg = '\x1B[45m'; // Magenta background
        levelText = '\x1B[37m'; // White text
        break;
      case LogLevel.info:
        levelBg = '\x1B[42m'; // Green background
        levelText = '\x1B[30m'; // Black text
        break;
      case LogLevel.warning:
        levelBg = '\x1B[43m'; // Yellow background
        levelText = '\x1B[30m'; // Black text
        break;
      case LogLevel.error:
        levelBg = '\x1B[41m'; // Red background
        levelText = '\x1B[37m'; // White text
        break;
      case LogLevel.fatal:
        levelBg = '\x1B[101m'; // Bright red background
        levelText = '\x1B[37m'; // White text
        break;
      case LogLevel.none:
        levelBg = '\x1B[47m'; // White background
        levelText = '\x1B[30m'; // Black text
        break;
    }

    // Format the header with visual styling
    final String hypnTechPart =
        '$hypnTechBg$hypnTechText$bold HYPN-TECH $reset';
    final String strategicLoggerPart =
        '$strategicLoggerBg$strategicLoggerText$bold STRATEGIC-LOGGER $reset';
    final String levelPart =
        '$levelBg$levelText$bold ${level.name.toUpperCase()} $reset';

    return '$hypnTechPart$strategicLoggerPart$levelPart$message';
  }

  /// Legacy message formatting for backward compatibility
  String _formatLegacyMessage(
    LogEntry entry,
    Map<String, dynamic> mergedContext,
  ) {
    final buffer = StringBuffer();

    if (entry.event != null) {
      buffer.write(
        'eventName: ${entry.event!.eventName} eventMessage: ${entry.event!.eventMessage ?? "No message"} message: ${entry.message}',
      );
    } else {
      buffer.write('${entry.message}');
    }

    if (mergedContext.isNotEmpty) {
      buffer.write(' Context: $mergedContext');
    }

    if (entry.stackTrace != null) {
      buffer.write(' Stack Trace: ${entry.stackTrace}');
    }

    return buffer.toString();
  }
}
