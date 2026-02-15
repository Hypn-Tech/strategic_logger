export 'src/strategic_logger.dart';

/// Log entry data class used by all strategies.
///
/// Contains message, level, timestamp, context, event, and stack trace.
/// Strategies receive this complete entry for formatting and routing.
export 'src/core/log_queue.dart' show LogEntry;

/// Base class for all log strategies.
///
/// Extend this class to create custom log strategies. It defines the essential methods
/// that all log strategies must implement, such as `log()`, `error()`, and `fatal()`.
export 'src/strategies/log_strategy.dart';

/// Base class for log events.
///
/// This class can be extended to define custom log events that carry specific data
/// relevant to your custom log strategy. It includes properties like event name and
/// parameters that facilitate passing rich data in logs.
export 'src/events/log_event.dart';

/// Enumerates the different log levels used within the logger.
///
/// Understanding these levels is crucial when developing custom log strategies,
/// as it helps in deciding how to handle different severities of log messages.
export 'src/enums/log_level.dart';
