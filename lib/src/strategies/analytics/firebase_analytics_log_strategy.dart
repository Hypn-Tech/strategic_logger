import 'dart:convert';
import 'dart:developer' as developer;

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:strategic_logger/logger_extension.dart';

import '../../core/isolate_manager.dart';
import 'firebase_analytics_log_event.dart';

/// A [LogStrategy] implementation that utilizes Firebase Analytics to log events, errors, and fatal incidents.
///
/// This strategy enables detailed tracking and logging of application activities in Firebase Analytics,
/// supporting data-driven decisions and comprehensive monitoring. It integrates seamlessly with Firebase
/// to provide real-time analytics based on the application's operational events.
///
/// The strategy supports handling both structured [LogEvent] instances and simple message logging, adapting
/// to the flexible needs of modern applications.
///
/// Example:
/// ```dart
/// var firebaseAnalyticsStrategy = FirebaseAnalyticsLogStrategy(logLevel: LogLevel.info);
/// var logger = StrategicLogger(strategies: [firebaseAnalyticsStrategy]);
/// logger.log("UserLoggedIn");
///
/// // Disable isolate if needed
/// var analyticsWithoutIsolate = FirebaseAnalyticsLogStrategy(useIsolate: false);
/// ```
class FirebaseAnalyticsLogStrategy extends LogStrategy {
  /// A static instance of [FirebaseAnalytics], used to interact with Firebase Analytics throughout the application.
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// Constructs a [FirebaseAnalyticsLogStrategy].
  ///
  /// [logLevel] sets the log level at which this strategy becomes active, allowing for targeted logging based on severity.
  /// [supportedEvents] optionally specifies which types of [LogEvent] this strategy should handle, enhancing event filtering.
  /// [useIsolate] whether to use isolates for context serialization.
  ///   Defaults to TRUE because context can contain heavy data.
  FirebaseAnalyticsLogStrategy({
    super.logLevel = LogLevel.none,
    super.supportedEvents,
    super.useIsolate =
        true, // Default: TRUE (context serialization can be heavy)
  });

  /// Logs a message or a structured event to Firebase Analytics.
  ///
  /// [entry] - The complete log entry containing message, level, timestamp, context, and event.
  @override
  Future<void> log(LogEntry entry) async {
    try {
      if (shouldLog(event: entry.event)) {
        // Use the unified mergedContext getter, serialize and cast for Firebase compatibility
        final context = entry.mergedContext;
        final parameters = context.isNotEmpty
            ? (await _serializeContext(context)).cast<String, Object>()
            : <String, Object>{};

        if (entry.event != null && entry.event is FirebaseAnalyticsLogEvent) {
          final analyticsEvent = entry.event as FirebaseAnalyticsLogEvent;
          _analytics.logEvent(
            name: analyticsEvent.eventName,
            parameters: parameters.isNotEmpty ? parameters : null,
          );
        }
      }
    } catch (e, stack) {
      developer.log(
        'Error during Firebase Analytics logging: $e',
        name: 'FirebaseAnalyticsLogStrategy',
        error: e,
        stackTrace: stack,
      );
    }
  }

  /// Logs a message or a structured event to Firebase Analytics.
  ///
  /// [entry] - The complete log entry containing message, level, timestamp, context, and event.
  @override
  Future<void> info(LogEntry entry) async {
    await log(entry);
  }

  /// Logs an error with detailed context to Firebase Analytics.
  ///
  /// [entry] - The complete log entry containing error message, level, timestamp, context, stackTrace, and event.
  @override
  Future<void> error(LogEntry entry) async {
    try {
      if (shouldLog(event: entry.event)) {
        // Use the unified mergedContext getter with error-specific parameters
        final context = entry.mergedContext;
        final serializedContext = context.isNotEmpty
            ? await _serializeContext(context)
            : <String, dynamic>{};

        final parameters = <String, Object>{
          'param_message': entry.message.toString(),
          'param_error':
              entry.stackTrace?.toString() ?? 'no_exception_provided',
          ...serializedContext.cast<String, Object>(),
        };
        if (entry.event != null && entry.event is FirebaseAnalyticsLogEvent) {
          final analyticsEvent = entry.event as FirebaseAnalyticsLogEvent;
          parameters['param_event_type'] = analyticsEvent.eventName;
        }
        _analytics.logEvent(name: 'event_name_error', parameters: parameters);
      }
    } catch (e, stack) {
      developer.log(
        'Error during Firebase Analytics error handling: $e',
        name: 'FirebaseAnalyticsLogStrategy',
        error: e,
        stackTrace: stack,
      );
    }
  }

  /// Marks an error as fatal and records it to Firebase Analytics.
  ///
  /// [entry] - The complete log entry containing fatal error message, level, timestamp, context, stackTrace, and event.
  @override
  Future<void> fatal(LogEntry entry) async {
    try {
      if (shouldLog(event: entry.event)) {
        // Use the unified mergedContext getter with fatal-specific parameters
        final context = entry.mergedContext;
        final serializedContext = context.isNotEmpty
            ? await _serializeContext(context)
            : <String, dynamic>{};

        final parameters = <String, Object>{
          'param_message': entry.message.toString(),
          'param_error':
              entry.stackTrace?.toString() ?? 'no_exception_provided',
          ...serializedContext.cast<String, Object>(),
        };
        if (entry.event != null && entry.event is FirebaseAnalyticsLogEvent) {
          final analyticsEvent = entry.event as FirebaseAnalyticsLogEvent;
          parameters['param_event_type'] = analyticsEvent.eventName;
        }
        _analytics.logEvent(name: 'fatal_error', parameters: parameters);
      }
    } catch (e, stack) {
      developer.log(
        'Error during Firebase Analytics fatal error handling: $e',
        name: 'FirebaseAnalyticsLogStrategy',
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
