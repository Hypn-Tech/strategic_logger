import 'dart:developer' as developer;

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:strategic_logger/logger_extension.dart';

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
/// ```
class FirebaseAnalyticsLogStrategy extends LogStrategy {
  /// A static instance of [FirebaseAnalytics], used to interact with Firebase Analytics throughout the application.
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// Constructs a [FirebaseAnalyticsLogStrategy].
  ///
  /// [logLevel] sets the log level at which this strategy becomes active, allowing for targeted logging based on severity.
  /// [supportedEvents] optionally specifies which types of [LogEvent] this strategy should handle, enhancing event filtering.
  FirebaseAnalyticsLogStrategy({
    super.logLevel = LogLevel.none,
    super.supportedEvents,
  });

  /// Logs a message or a structured event to Firebase Analytics, facilitating broad and detailed analytics.
  ///
  /// [message] - The general message to log if no specific event is provided. Treated as the event name in Firebase.
  /// [event] - An optional [LogEvent] providing structured data for logging, allowing for more granified event analysis.
  /// [context] - Optional. Additional context data.
  @override
  Future<void> log({dynamic message, LogEvent? event, Map<String, dynamic>? context}) async {
    try {
      if (shouldLog(event: event)) {
        developer.log(
          '>>═══════════════════════FIREBASE ANALYTICS LOG STRATEGY [INFO/LOG]═══════════════════════<<',
          name: 'FirebaseAnalyticsLogStrategy',
        );
        if (event != null) {
          final FirebaseAnalyticsLogEvent analyticsEvent =
              event as FirebaseAnalyticsLogEvent;
          
          // Merge context with event parameters
          Map<String, Object>? parameters = analyticsEvent.parameters != null
              ? Map<String, Object>.from(analyticsEvent.parameters!)
              : <String, Object>{};
          
          if (context != null && context.isNotEmpty) {
            // Convert context values to Object type for Firebase Analytics
            context.forEach((key, value) {
              // Firebase Analytics accepts most primitive types
              if (value is String || value is num || value is bool || value is List || value is Map) {
                parameters[key] = value as Object;
              } else {
                // Convert other types to string
                parameters[key] = value.toString();
              }
            });
          }
          
          await _analytics.logEvent(
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

  /// Logs a message or a structured event to Firebase Analytics, facilitating broad and detailed analytics.
  ///
  /// [message] - The general message to log if no specific event is provided. Treated as the event name in Firebase.
  /// [event] - An optional [LogEvent] providing structured data for logging, allowing for more granified event analysis.
  /// [context] - Optional. Additional context data.
  @override
  Future<void> info({dynamic message, LogEvent? event, Map<String, dynamic>? context}) async {
    try {
      await log(message: message, event: event, context: context);
    } catch (e, stack) {
      developer.log(
        'Error during Firebase Analytics logging: $e',
        name: 'FirebaseAnalyticsLogStrategy',
        error: e,
        stackTrace: stack,
      );
    }
  }

  /// Logs an error with detailed context to Firebase Analytics, categorizing it appropriately based on severity.
  ///
  /// [error] - The error to log, used for detailed error tracking.
  /// [stackTrace] - The stack trace associated with the error, providing deeper insight for debugging purposes.
  /// [event] - An optional [LogEvent] providing additional context for the error, enhancing error analysis.
  /// [context] - Optional. Additional context data.
  @override
  Future<void> error({
    dynamic error,
    StackTrace? stackTrace,
    LogEvent? event,
    Map<String, dynamic>? context,
  }) async {
    try {
      if (shouldLog(event: event)) {
        developer.log(
          '>>═══════════════════════FIREBASE ANALYTICS LOG STRATEGY [ERROR]═══════════════════════<<',
          name: 'FirebaseAnalyticsLogStrategy',
        );
        if (event != null) {
          final FirebaseAnalyticsLogEvent analyticsEvent =
              event as FirebaseAnalyticsLogEvent;
          
          Map<String, Object> parameters = {
            'param_message': error.toString(),
            'param_error': stackTrace?.toString() ?? 'no_exception_provided',
            'param_event_type': analyticsEvent.eventName,
          };
          
          // Add context to parameters with type conversion
          if (context != null && context.isNotEmpty) {
            context.forEach((key, value) {
              if (value is String || value is num || value is bool || value is List || value is Map) {
                parameters[key] = value as Object;
              } else {
                parameters[key] = value.toString();
              }
            });
          }
          
          await _analytics.logEvent(
            name: 'event_name_error',
            parameters: parameters,
          );
        } else {
          // Even without event, add context if available
          Map<String, Object>? parameters;
          if (context != null && context.isNotEmpty) {
            parameters = <String, Object>{};
            context.forEach((key, value) {
              if (value is String || value is num || value is bool || value is List || value is Map) {
                parameters![key] = value as Object;
              } else {
                parameters![key] = value.toString();
              }
            });
          }
          await _analytics.logEvent(name: '$error', parameters: parameters);
        }
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

  /// Marks an error as fatal and records it to Firebase Analytics, ensuring it is flagged as a critical incident.
  ///
  /// [error] - The critical error to log as fatal.
  /// [stackTrace] - The stack trace associated with the critical error, providing detailed context for system failures.
  /// [event] - An optional [LogEvent] providing additional context for the critical error, aiding in root cause analysis.
  /// [context] - Optional. Additional context data.
  @override
  Future<void> fatal({error, StackTrace? stackTrace, LogEvent? event, Map<String, dynamic>? context}) async {
    try {
      if (shouldLog(event: event)) {
        developer.log(
          '>>═══════════════════════FIREBASE ANALYTICS LOG STRATEGY [FATAL]═══════════════════════<<',
          name: 'FirebaseAnalyticsLogStrategy',
        );
        if (event != null) {
          final FirebaseAnalyticsLogEvent analyticsEvent =
              event as FirebaseAnalyticsLogEvent;
          
          Map<String, Object> parameters = {
            'param_message': error.toString(),
            'param_error': stackTrace?.toString() ?? 'no_exception_provided',
            'param_event_type': analyticsEvent.eventName,
          };
          
          // Add context to parameters with type conversion
          if (context != null && context.isNotEmpty) {
            context.forEach((key, value) {
              if (value is String || value is num || value is bool || value is List || value is Map) {
                parameters[key] = value as Object;
              } else {
                parameters[key] = value.toString();
              }
            });
          }
          
          await _analytics.logEvent(
            name: 'fatal_error',
            parameters: parameters,
          );
        } else {
          // Even without event, add context if available
          Map<String, Object>? parameters;
          if (context != null && context.isNotEmpty) {
            parameters = <String, Object>{};
            context.forEach((key, value) {
              if (value is String || value is num || value is bool || value is List || value is Map) {
                parameters![key] = value as Object;
              } else {
                parameters![key] = value.toString();
              }
            });
          }
          await _analytics.logEvent(name: 'FATAL: $error', parameters: parameters);
        }
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
}
