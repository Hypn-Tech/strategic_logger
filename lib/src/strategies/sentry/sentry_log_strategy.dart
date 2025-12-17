import 'dart:developer' as developer;
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:strategic_logger/logger_extension.dart';
import '../../core/log_queue.dart';
import '../../strategies/sentry/sentry_log_event.dart';

/// A [LogStrategy] implementation that logs messages and errors to Sentry.
///
/// This strategy provides the functionality to send log messages and detailed error reports,
/// including stack traces, to Sentry. It can be configured with a specific log level
/// and can handle both general log messages and structured [LogEvent] instances tailored for Sentry.
///
/// The strategy distinguishes between general messages, errors, and fatal errors, ensuring that each
/// type of log is appropriately reported to Sentry.
///
/// Example:
/// ```dart
/// var sentryStrategy = SentryLogStrategy(
///   logLevel: LogLevel.error,
/// );
/// var logger = StrategicLogger(strategies: [sentryStrategy]);
/// logger.error('Example error', stackTrace: StackTrace.current);
/// ```
class SentryLogStrategy extends LogStrategy {
  /// Constructs a [SentryLogStrategy].
  ///
  /// [logLevel] sets the log level at which this strategy becomes active.
  /// [supportedEvents] optionally specifies which types of [LogEvent] this strategy should handle.
  SentryLogStrategy({super.logLevel = LogLevel.none, super.supportedEvents});

  /// Logs a message or a structured event to Sentry.
  ///
  /// [entry] - The complete log entry containing message, level, timestamp, context, and event.
  @override
  Future<void> log(LogEntry entry) async {
    try {
      if (shouldLog(event: entry.event)) {
        // Merge context from entry.context and event.parameters
        final context = <String, dynamic>{};
        if (entry.context != null) {
          context.addAll(entry.context!);
        }
        if (entry.event?.parameters != null) {
          context.addAll(entry.event!.parameters!);
        }

        // Add context to Sentry
        if (context.isNotEmpty) {
          Sentry.configureScope((scope) {
            context.forEach((key, value) {
              scope.setExtra(key, value);
            });
          });
        }

        if (entry.event != null && entry.event is SentryLogEvent) {
          final sentryEvent = entry.event as SentryLogEvent;
          Sentry.captureMessage(
            '${sentryEvent.eventName}: ${sentryEvent.eventMessage}',
          );
        } else {
          Sentry.captureMessage('Message: ${entry.message}');
        }
      }
    } catch (e, stack) {
      developer.log(
        'Error during logging in Sentry Strategy',
        name: 'SentryLogStrategy',
        error: e,
        stackTrace: stack,
      );
    }
  }

  /// Logs a message or a structured event to Sentry.
  ///
  /// [entry] - The complete log entry containing message, level, timestamp, context, and event.
  @override
  Future<void> info(LogEntry entry) async {
    await log(entry);
  }

  /// Records an error or a structured event with an error to Sentry.
  ///
  /// [entry] - The complete log entry containing error message, level, timestamp, context, stackTrace, and event.
  @override
  Future<void> error(LogEntry entry) async {
    try {
      if (shouldLog(event: entry.event)) {
        // Merge context from entry.context and event.parameters
        final context = <String, dynamic>{};
        if (entry.context != null) {
          context.addAll(entry.context!);
        }
        if (entry.event?.parameters != null) {
          context.addAll(entry.event!.parameters!);
        }

        // Add context to Sentry
        if (context.isNotEmpty) {
          Sentry.configureScope((scope) {
            context.forEach((key, value) {
              scope.setExtra(key, value);
            });
          });
        }

        Sentry.captureException(entry.message, stackTrace: entry.stackTrace);
      }
    } catch (e, stack) {
      developer.log(
        'Error during error handling in Sentry Strategy',
        name: 'SentryLogStrategy',
        error: e,
        stackTrace: stack,
      );
    }
  }

  /// Marks an error as fatal and records it to Sentry.
  ///
  /// [entry] - The complete log entry containing fatal error message, level, timestamp, context, stackTrace, and event.
  @override
  Future<void> fatal(LogEntry entry) async {
    try {
      if (shouldLog(event: entry.event)) {
        // Merge context from entry.context and event.parameters
        final context = <String, dynamic>{};
        if (entry.context != null) {
          context.addAll(entry.context!);
        }
        if (entry.event?.parameters != null) {
          context.addAll(entry.event!.parameters!);
        }

        // Add context to Sentry
        if (context.isNotEmpty) {
          Sentry.configureScope((scope) {
            context.forEach((key, value) {
              scope.setExtra(key, value);
            });
          });
        }

        Sentry.captureException(entry.message, stackTrace: entry.stackTrace);
      }
    } catch (e, stack) {
      developer.log(
        'Error during fatal error handling in Sentry Strategy',
        name: 'SentryLogStrategy',
        error: e,
        stackTrace: stack,
      );
    }
  }
}
