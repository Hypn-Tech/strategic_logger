import 'dart:developer' as developer;

import '../../console/modern_console_formatter.dart';
import '../../console/terminal_capabilities.dart';
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
/// - Optional isolate-based processing (disabled by default for performance)
/// - Performance monitoring
/// - Structured output with context and events
///
/// Example:
/// ```dart
/// var consoleStrategy = ConsoleLogStrategy(logLevel: LogLevel.info);
/// var logger = StrategicLogger(strategies: [consoleStrategy]);
/// logger.log("A simple log message.");
///
/// // Enable isolate for heavy formatting (optional)
/// var consoleWithIsolate = ConsoleLogStrategy(useIsolate: true);
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
  /// [useIsolate] whether to use isolates for log formatting. Defaults to FALSE
  ///   because console formatting is lightweight. Set to true for heavy formatting loads.
  /// [useModernFormatting] enables modern console formatting with colors and emojis.
  /// [useColors] enables colored output. When [autoDetectColors] is true (default),
  /// this is combined with terminal capability detection.
  /// [autoDetectColors] when true (default), automatically detects if the terminal
  /// supports ANSI colors. iOS/Android consoles don't support ANSI, so colors are
  /// disabled automatically to avoid garbage output like `\^[[36m`.
  /// [showTimestamp] shows timestamp in logs.
  /// [showContext] shows context information in logs.
  ConsoleLogStrategy({
    super.logLevel = LogLevel.none,
    super.supportedEvents,
    bool useIsolate = false, // Console: default FALSE (lightweight operation)
    bool useModernFormatting = true,
    bool useColors = true,
    bool autoDetectColors = true,
    bool showTimestamp = true,
    bool showContext = true,
  }) : _useModernFormatting = useModernFormatting,
       _useColors = autoDetectColors
           ? (useColors && TerminalCapabilities.supportsAnsiColors)
           : useColors,
       _showTimestamp = showTimestamp,
       _showContext = showContext,
       super(useIsolate: useIsolate);

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

      // Use the unified mergedContext getter
      final mergedContext = entry.mergedContext;

      String formattedMessage;

      if (_useModernFormatting) {
        if (useIsolate) {
          // Use isolate for heavy formatting
          try {
            final formatted = await isolateManager.formatLog(
              message: entry.message.toString(),
              level: entry.level.name,
              timestamp: entry.timestamp,
              context: mergedContext.isNotEmpty ? mergedContext : null,
            );
            formattedMessage = formatted['formatted'] as String;
          } catch (e) {
            // Fallback to direct formatting if isolate fails
            formattedMessage = _formatDirect(entry, mergedContext);
          }
        } else {
          // Direct formatting without isolate (default for Console)
          formattedMessage = _formatDirect(entry, mergedContext);
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

  /// Formats a log entry directly without using isolate
  String _formatDirect(LogEntry entry, Map<String, dynamic> mergedContext) {
    return modernConsoleFormatter.formatLog(
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

  /// Formats the log header with visual styling and colors
  String _formatLogHeader(LogLevel level, String message) {
    // Simply return the message - the modern formatter already adds everything needed
    return message;
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
