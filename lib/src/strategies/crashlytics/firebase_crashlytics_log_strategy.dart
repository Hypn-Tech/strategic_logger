import 'dart:convert';
import 'dart:developer' as developer;
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:strategic_logger/logger_extension.dart';

import '../../core/isolate_manager.dart';
import '../../core/log_queue.dart';
import 'firebase_crashlytics_log_event.dart';

/// A [LogStrategy] implementation that logs messages and errors to Firebase Crashlytics.
///
/// This strategy provides the functionality to send log messages and detailed error reports,
/// including stack traces, to Firebase Crashlytics. It can be configured with a specific log level
/// and can handle both general log messages and structured [LogEvent] instances tailored for Crashlytics.
///
/// The strategy distinguishes between general messages, errors, and fatal errors, ensuring that each
/// type of log is appropriately reported to Firebase Crashlytics.
///
/// Example:
/// ```dart
/// var crashlyticsStrategy = FirebaseCrashlyticsLogStrategy(
///   logLevel: LogLevel.error,
/// );
/// var logger = StrategicLogger(strategies: [crashlyticsStrategy]);
/// logger.error('Example error', stackTrace: StackTrace.current);
///
/// // Disable isolate if needed
/// var crashlyticsWithoutIsolate = FirebaseCrashlyticsLogStrategy(useIsolate: false);
/// ```
class FirebaseCrashlyticsLogStrategy extends LogStrategy {
  /// Constructs a [FirebaseCrashlyticsLogStrategy].
  ///
  /// [logLevel] sets the log level at which this strategy becomes active.
  /// [supportedEvents] optionally specifies which types of [LogEvent] this strategy should handle.
  /// [useIsolate] whether to use isolates for context serialization.
  ///   Defaults to TRUE because context can contain heavy data.
  FirebaseCrashlyticsLogStrategy({
    super.logLevel = LogLevel.none,
    super.supportedEvents,
    bool useIsolate = true, // Default: TRUE (context serialization can be heavy)
  }) : super(useIsolate: useIsolate);

  /// Logs a message or a structured event to Firebase Crashlytics.
  ///
  /// [entry] - The complete log entry containing message, level, timestamp, context, and event.
  @override
  Future<void> log(LogEntry entry) async {
    try {
      if (shouldLog(event: entry.event)) {
        // Use the unified mergedContext getter
        final contextInfo = entry.mergedContext;

        // Set custom keys from context
        if (contextInfo.isNotEmpty) {
          final serializedContext = await _serializeContext(contextInfo);
          serializedContext.forEach((key, value) {
            FirebaseCrashlytics.instance.setCustomKey(key, value.toString());
          });
        }

        if (entry.event != null && entry.event is FirebaseCrashlyticsLogEvent) {
          final crashlyticsEvent = entry.event as FirebaseCrashlyticsLogEvent;
          FirebaseCrashlytics.instance.log(
            '${crashlyticsEvent.eventName}: ${crashlyticsEvent.eventMessage ?? entry.message}',
          );
        } else {
          FirebaseCrashlytics.instance.log('Message: ${entry.message}');
        }
      }
    } catch (e, stack) {
      developer.log(
        'Error during logging in Firebase Crashlytics Strategy',
        name: 'FirebaseCrashlyticsLogStrategy',
        error: e,
        stackTrace: stack,
      );
    }
  }

  /// Logs a message or a structured event to Firebase Crashlytics.
  ///
  /// [entry] - The complete log entry containing message, level, timestamp, context, and event.
  @override
  Future<void> info(LogEntry entry) async {
    await log(entry);
  }

  /// Records an error or a structured event with an error to Firebase Crashlytics.
  ///
  /// [entry] - The complete log entry containing error message, level, timestamp, context, stackTrace, and event.
  @override
  Future<void> error(LogEntry entry) async {
    try {
      if (shouldLog(event: entry.event)) {
        // Use the unified mergedContext getter
        final contextInfo = entry.mergedContext;

        // Set custom keys from context
        if (contextInfo.isNotEmpty) {
          final serializedContext = await _serializeContext(contextInfo);
          serializedContext.forEach((key, value) {
            FirebaseCrashlytics.instance.setCustomKey(key, value.toString());
          });
        }

        if (entry.event != null && entry.event is FirebaseCrashlyticsLogEvent) {
          final crashlyticsEvent = entry.event as FirebaseCrashlyticsLogEvent;
          FirebaseCrashlytics.instance.recordError(
            entry.message,
            entry.stackTrace,
            reason: crashlyticsEvent.eventMessage,
          );
        } else {
          FirebaseCrashlytics.instance.recordError(
            entry.message,
            entry.stackTrace,
          );
        }
      }
    } catch (e, stack) {
      developer.log(
        'Error during error handling in Firebase Crashlytics Strategy',
        name: 'FirebaseCrashlyticsLogStrategy',
        error: e,
        stackTrace: stack,
      );
    }
  }

  /// Marks an error as fatal and records it to Firebase Crashlytics.
  ///
  /// [entry] - The complete log entry containing fatal error message, level, timestamp, context, stackTrace, and event.
  @override
  Future<void> fatal(LogEntry entry) async {
    try {
      if (shouldLog(event: entry.event)) {
        // Use the unified mergedContext getter
        final contextInfo = entry.mergedContext;

        // Set custom keys from context
        if (contextInfo.isNotEmpty) {
          final serializedContext = await _serializeContext(contextInfo);
          serializedContext.forEach((key, value) {
            FirebaseCrashlytics.instance.setCustomKey(key, value.toString());
          });
        }

        if (entry.event != null && entry.event is FirebaseCrashlyticsLogEvent) {
          final crashlyticsEvent = entry.event as FirebaseCrashlyticsLogEvent;
          FirebaseCrashlytics.instance.recordError(
            entry.message,
            entry.stackTrace,
            reason: crashlyticsEvent.eventMessage,
            fatal: true,
          );
        } else {
          FirebaseCrashlytics.instance.recordError(
            entry.message,
            entry.stackTrace,
            fatal: true,
          );
        }
      }
    } catch (e, stack) {
      developer.log(
        'Error during fatal error handling in Firebase Crashlytics Strategy',
        name: 'FirebaseCrashlyticsLogStrategy',
        error: e,
        stackTrace: stack,
      );
    }
  }

  /// Serializes context using isolate or directly based on useIsolate flag.
  Future<Map<String, dynamic>> _serializeContext(
    Map<String, dynamic> context,
  ) async {
    if (useIsolate) {
      try {
        return await isolateManager.serializeContext(context);
      } catch (e) {
        // Fallback to direct serialization
        return _serializeContextDirect(context);
      }
    }
    return _serializeContextDirect(context);
  }

  /// Serializes context directly on main thread (fallback or when useIsolate=false)
  Map<String, dynamic> _serializeContextDirect(Map<String, dynamic> context) {
    final serialized = <String, dynamic>{};
    context.forEach((key, value) {
      if (value is Map || value is List) {
        serialized[key] = jsonEncode(value);
      } else {
        serialized[key] = value.toString();
      }
    });
    return serialized;
  }
}
