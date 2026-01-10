import 'dart:async';
import 'dart:developer' as developer;

import 'console/terminal_capabilities.dart';
import 'core/isolate_manager.dart';
import 'core/log_queue.dart';
import 'core/performance_monitor.dart';
import 'enums/log_level.dart';

import 'errors/alread_initialized_error.dart';
import 'errors/not_initialized_error.dart';
import 'events/log_event.dart';
import 'strategies/log_strategy.dart';

// Platform detection
import 'package:flutter/foundation.dart' show kIsWeb;

/// A flexible and centralized logger that supports multiple logging strategies.
///
/// `StrategicLogger` is designed to handle logging across various levels and strategies,
/// allowing for detailed logging control throughout an application. It ensures that only a single
/// instance of the logger is initialized and used throughout the application lifecycle.
///
/// The logger must be initialized before use, with the desired log level and strategies provided.
/// After initialization, the logger can be reconfigured, but this should be used with caution to
/// avoid unintended side effects during the application lifecycle.
///
/// Features:
/// - Isolate-based processing for heavy operations
/// - Performance monitoring and metrics
/// - Modern console formatting with colors and emojis
/// - Compatibility with popular logger packages
/// - Async queue with backpressure control
///
/// Example:
/// ```dart
/// await logger.initialize(strategies: [ConsoleLogStrategy()], level: LogLevel.info);
/// logger.log("Application started.");
/// ```
StrategicLogger logger = StrategicLogger();

class StrategicLogger {
  bool _isInitialized = false;

  /// Indicates whether the logger has been initialized.
  bool get isInitialized => _isInitialized;

  /// Determines if isolates are supported on the current platform.
  ///
  /// Returns false for web platform and true for all other platforms.
  bool _isIsolateSupported() {
    if (kIsWeb) {
      return false; // Isolates not supported on web
    }
    return true; // Isolates supported on mobile/desktop
  }

  LogLevel _initLogLevel = LogLevel.none;

  /// Current log level of the logger.
  LogLevel get level => _initLogLevel;

  List<LogStrategy> _strategies = [];

  // Modern features
  LogQueue? _logQueue;
  bool _useIsolates = true;
  bool _enablePerformanceMonitoring = true;
  bool _enableModernConsole = true;
  String? _projectName;

  /// Stream controller for real-time log updates
  StreamController<LogEntry> _logStreamController =
      StreamController<LogEntry>.broadcast();

  /// Stream of log entries for real-time console updates
  Stream<LogEntry> get logStream => _logStreamController.stream;

  /// Reconfigures the logger even if it has been previously initialized.
  ///
  /// This should be used with caution, as reconfiguring a logger that is already in use can lead to inconsistent logging behavior.
  ///
  /// [strategies] - List of new strategies to use for logging.
  /// [level] - The minimum log level to log. Defaults to [LogLevel.none].
  /// [useIsolates] - Whether to use isolates for heavy operations. Defaults to true.
  /// [enablePerformanceMonitoring] - Whether to enable performance monitoring. Defaults to true.
  /// [enableModernConsole] - Whether to enable modern console formatting. Defaults to true.
  /// [projectName] - Custom project name to display in the banner. If not provided, preserves the previous value.
  Future<void> reconfigure({
    List<LogStrategy>? strategies,
    LogLevel level = LogLevel.none,
    bool useIsolates = true,
    bool enablePerformanceMonitoring = true,
    bool enableModernConsole = true,
    String? projectName,
  }) async {
    await logger._initialize(
      strategies: strategies,
      level: level,
      force: true,
      useIsolates: useIsolates,
      enablePerformanceMonitoring: enablePerformanceMonitoring,
      enableModernConsole: enableModernConsole,
      projectName: projectName,
    );
  }

  /// Configures the logger if it has not been initialized.
  ///
  /// This method should be used for the initial setup of the logger.
  ///
  /// [strategies] - List of strategies to use for logging.
  /// [level] - The minimum log level to log. Defaults to [LogLevel.none].
  /// [useIsolates] - Whether to use isolates for heavy operations. Defaults to true.
  /// [enablePerformanceMonitoring] - Whether to enable performance monitoring. Defaults to true.
  /// [enableModernConsole] - Whether to enable modern console formatting. Defaults to true.
  /// [projectName] - Custom project name to display in the banner. If not provided, uses default.
  Future<void> initialize({
    List<LogStrategy>? strategies,
    LogLevel level = LogLevel.none,
    bool? useIsolates, // Made nullable to allow auto-detection
    bool enablePerformanceMonitoring = true,
    bool enableModernConsole = true,
    bool force = false, // Allow re-initialization for testing
    String? projectName,
  }) async {
    // Auto-detect platform support for isolates
    final shouldUseIsolates = useIsolates ?? _isIsolateSupported();

    await logger._initialize(
      strategies: strategies,
      level: level,
      force: force,
      useIsolates: shouldUseIsolates,
      enablePerformanceMonitoring: enablePerformanceMonitoring,
      enableModernConsole: enableModernConsole,
      projectName: projectName,
    );
  }

  /// Initializes or reinitializes the logger with specified strategies and log level.
  ///
  /// Throws [AlreadyInitializedError] if the logger is already initialized and [force] is not set to true.
  ///
  /// [strategies] - List of strategies to use for logging.
  /// [level] - The minimum log level to log. Defaults to [LogLevel.none].
  /// [force] - Forces reinitialization if set to true.
  /// [useIsolates] - Whether to use isolates for heavy operations.
  /// [enablePerformanceMonitoring] - Whether to enable performance monitoring.
  /// [enableModernConsole] - Whether to enable modern console formatting.
  /// [projectName] - Custom project name to display in the banner.
  Future<StrategicLogger> _initialize({
    List<LogStrategy>? strategies,
    LogLevel level = LogLevel.none,
    bool force = false,
    bool useIsolates = true,
    bool enablePerformanceMonitoring = true,
    bool enableModernConsole = true,
    String? projectName,
  }) async {
    // Only update project name if a new one is provided
    if (projectName != null) {
      _projectName = projectName;
    }
    final isReconfiguration = _isInitialized && force;

    if (_isInitialized && !force) {
      throw AlreadyInitializedError();
    }

    // If already initialized and force is true, dispose first
    if (isReconfiguration) {
      // Clean up resources but keep _isInitialized false
      try {
        _logQueue?.dispose();
        _logQueue = null;
        if (_useIsolates) {
          try {
            isolateManager.dispose();
          } catch (e) {
            // Ignore
          }
        }
        try {
          performanceMonitor.dispose();
        } catch (e) {
          // Ignore
        }
        try {
          if (!_logStreamController.isClosed) {
            _logStreamController.close();
          }
        } catch (e) {
          // Ignore
        }
      } catch (e) {
        // Ignore errors during cleanup
      }
      _isInitialized = false;
    }

    if (!_isInitialized) {
      // Recreate stream controller if closed
      if (_logStreamController.isClosed) {
        _logStreamController = StreamController<LogEntry>.broadcast();
      }

      // Initialize modern features
      _useIsolates = useIsolates;
      _enablePerformanceMonitoring = enablePerformanceMonitoring;
      _enableModernConsole = enableModernConsole;

      // Initialize isolate manager if enabled
      if (_useIsolates) {
        await isolateManager.initialize();
      }

      // Initialize log queue
      _logQueue?.dispose(); // Dispose existing if any
      _logQueue = LogQueue();
      _setupLogQueueListener();

      _initializeStrategies(strategies, level);

      // Set initialized BEFORE printing (which may use logger methods)
      _isInitialized = true;

      _printStrategicLoggerInit(isReconfiguration: isReconfiguration);
    }
    return logger;
  }

  /// Sets up the logging strategies and log level.
  void _initializeStrategies(List<LogStrategy>? strategies, LogLevel level) {
    logger._strategies = strategies ?? [];
    logger._initLogLevel = level;

    if (strategies != null && strategies.isNotEmpty) {
      for (var strategy in strategies) {
        if (strategy.logLevel == LogLevel.none) {
          strategy.logLevel = logger._initLogLevel;
        }
        strategy.loggerLogLevel = level;
      }
    }
  }

  /// Sets up the log queue listener for processing logs
  void _setupLogQueueListener() {
    _logQueue!.stream.listen((entry) async {
      await _processLogEntry(entry);
    });
  }

  /// Processes a log entry using strategies
  Future<void> _processLogEntry(LogEntry entry) async {
    // Emit to stream for real-time console updates
    if (!_logStreamController.isClosed) {
      _logStreamController.add(entry);
    }

    if (_enablePerformanceMonitoring) {
      await performanceMonitor.measureOperation('processLogEntry', () async {
        for (var strategy in _strategies) {
          await _executeStrategy(strategy, entry);
        }
      });
    } else {
      for (var strategy in _strategies) {
        await _executeStrategy(strategy, entry);
      }
    }
  }

  /// Executes a strategy for a log entry
  Future<void> _executeStrategy(LogStrategy strategy, LogEntry entry) async {
    try {
      switch (entry.level) {
        case LogLevel.debug:
          await strategy.log(entry);
          break;
        case LogLevel.info:
          await strategy.info(entry);
          break;
        case LogLevel.warning:
          await strategy.log(entry);
          break;
        case LogLevel.error:
          await strategy.error(entry);
          break;
        case LogLevel.fatal:
          await strategy.fatal(entry);
          break;
        case LogLevel.none:
          // Do nothing
          break;
      }
    } catch (e, stackTrace) {
      // Log strategy execution error
      developer.log(
        'Error executing strategy ${strategy.runtimeType}: $e',
        name: 'StrategicLogger',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Logs a message or event using the configured strategies.
  ///
  /// Throws [NotInitializedError] if the logger has not been initialized.
  ///
  /// [message] - The message to log.
  /// [event] - Optional. The specific log event associated with the message.
  /// [context] - Optional. Additional context data.
  Future<void> log(
    dynamic message, {
    LogEvent? event,
    Map<String, Object>? context,
  }) async {
    if (!_isInitialized) {
      throw NotInitializedError();
    }

    final entry = LogEntry.fromParams(
      message: message,
      level: LogLevel.info,
      event: event,
      context: context,
    );

    if (_logQueue == null) {
      throw NotInitializedError();
    }
    _logQueue!.enqueue(entry);
  }

  /// Logs a message or event using the configured strategies.
  ///
  /// Throws [NotInitializedError] if the logger has not been initialized.
  ///
  /// [message] - The message to log.
  /// [event] - Optional. The specific log event associated with the message.
  /// [context] - Optional. Additional context data.
  Future<void> info(
    dynamic message, {
    LogEvent? event,
    Map<String, Object>? context,
  }) async {
    if (!_isInitialized) {
      throw NotInitializedError();
    }

    final entry = LogEntry.fromParams(
      message: message,
      level: LogLevel.info,
      event: event,
      context: context,
    );

    if (_logQueue == null) {
      throw NotInitializedError();
    }
    _logQueue!.enqueue(entry);
  }

  /// Logs an error using the configured strategies.
  ///
  /// Throws [NotInitializedError] if the logger has not been initialized.
  ///
  /// [error] - The error object to log.
  /// [stackTrace] - The stack trace associated with the error.
  /// [event] - Optional. The specific log event associated with the error.
  /// [context] - Optional. Additional context data.
  Future<void> error(
    dynamic error, {
    StackTrace? stackTrace,
    LogEvent? event,
    Map<String, Object>? context,
  }) async {
    if (!_isInitialized) {
      throw NotInitializedError();
    }

    final entry = LogEntry.fromParams(
      message: error,
      level: LogLevel.error,
      event: event,
      context: context,
      stackTrace: stackTrace,
    );

    if (_logQueue == null) {
      throw NotInitializedError();
    }
    _logQueue!.enqueue(entry);
  }

  /// Logs a fatal error using the configured strategies.
  ///
  /// Throws [NotInitializedError] if the logger has not been initialized.
  ///
  /// [error] - The critical error object to log as fatal.
  /// [stackTrace] - The stack trace associated with the fatal error.
  /// [event] - Optional. The specific log event associated with the fatal error.
  /// [context] - Optional. Additional context data.
  Future<void> fatal(
    dynamic error, {
    StackTrace? stackTrace,
    LogEvent? event,
    Map<String, Object>? context,
  }) async {
    if (!_isInitialized) {
      throw NotInitializedError();
    }

    final entry = LogEntry.fromParams(
      message: error,
      level: LogLevel.fatal,
      event: event,
      context: context,
      stackTrace: stackTrace,
    );

    if (_logQueue == null) {
      throw NotInitializedError();
    }
    _logQueue!.enqueue(entry);
  }

  /// Synchronous debug logging (compatibility with popular logger packages)
  void debugSync(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    if (!_isInitialized) return;

    final entry = LogEntry.fromParams(
      message: message,
      level: LogLevel.debug,
      stackTrace: stackTrace,
    );

    if (_logQueue == null) {
      throw NotInitializedError();
    }
    _logQueue!.enqueue(entry);
  }

  /// Synchronous info logging (compatibility with popular logger packages)
  void infoSync(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    if (!_isInitialized) return;

    final entry = LogEntry.fromParams(
      message: message,
      level: LogLevel.info,
      stackTrace: stackTrace,
    );

    if (_logQueue == null) {
      throw NotInitializedError();
    }
    _logQueue!.enqueue(entry);
  }

  /// Synchronous warning logging (compatibility with popular logger packages)
  void warningSync(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    if (!_isInitialized) return;

    final entry = LogEntry.fromParams(
      message: message,
      level: LogLevel.warning,
      stackTrace: stackTrace,
    );

    if (_logQueue == null) {
      throw NotInitializedError();
    }
    _logQueue!.enqueue(entry);
  }

  /// Synchronous error logging (compatibility with popular logger packages)
  void errorSync(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    if (!_isInitialized) return;

    final entry = LogEntry.fromParams(
      message: message,
      level: LogLevel.error,
      stackTrace: stackTrace,
    );

    if (_logQueue == null) {
      throw NotInitializedError();
    }
    _logQueue!.enqueue(entry);
  }

  /// Synchronous fatal logging (compatibility with popular logger packages)
  void fatalSync(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    if (!_isInitialized) return;

    final entry = LogEntry.fromParams(
      message: message,
      level: LogLevel.fatal,
      stackTrace: stackTrace,
    );

    if (_logQueue == null) {
      throw NotInitializedError();
    }
    _logQueue!.enqueue(entry);
  }

  /// Synchronous verbose logging (alias for debug)
  void verboseSync(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    debugSync(message, error, stackTrace);
  }

  /// Synchronous log method (alias for info)
  void logSync(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    infoSync(message, error, stackTrace);
  }

  /// Logs a message with structured data
  Future<void> logStructured(
    LogLevel level,
    dynamic message, {
    Map<String, Object>? data,
    String? tag,
    DateTime? timestamp,
  }) async {
    if (!_isInitialized) {
      throw NotInitializedError();
    }

    final event = LogEvent(
      eventName: tag ?? 'LOG',
      eventMessage: message.toString(),
      parameters: data,
    );

    final entry = LogEntry.fromParams(
      message: message,
      level: level,
      event: event,
    );

    if (_logQueue == null) {
      throw NotInitializedError();
    }
    _logQueue!.enqueue(entry);
  }

  /// Adds debug level logging
  Future<void> debug(
    dynamic message, {
    LogEvent? event,
    Map<String, Object>? context,
  }) async {
    if (!_isInitialized) {
      throw NotInitializedError();
    }

    final entry = LogEntry.fromParams(
      message: message,
      level: LogLevel.debug,
      event: event,
      context: context,
    );

    if (_logQueue == null) {
      throw NotInitializedError();
    }
    _logQueue!.enqueue(entry);
  }

  /// Adds warning level logging
  Future<void> warning(
    dynamic message, {
    LogEvent? event,
    Map<String, Object>? context,
  }) async {
    if (!_isInitialized) {
      throw NotInitializedError();
    }

    final entry = LogEntry.fromParams(
      message: message,
      level: LogLevel.warning,
      event: event,
      context: context,
    );

    if (_logQueue == null) {
      throw NotInitializedError();
    }
    _logQueue!.enqueue(entry);
  }

  /// Adds verbose level logging (alias for debug)
  Future<void> verbose(
    dynamic message, {
    LogEvent? event,
    Map<String, Object>? context,
  }) async {
    await debug(message, event: event, context: context);
  }

  /// Forces flush of all queued logs
  void flush() {
    _logQueue?.flush();
  }

  /// Gets performance statistics
  Map<String, dynamic> getPerformanceStats() {
    return performanceMonitor.getAllStats().map(
      (key, value) => MapEntry(key, value.toString()),
    );
  }

  /// Disposes the logger and cleans up resources
  void dispose() {
    if (!_isInitialized) {
      return; // Already disposed or never initialized
    }
    try {
      _logQueue?.dispose();
      _logQueue = null;
    } catch (e) {
      // Ignore errors during dispose
      _logQueue = null;
    }
    if (_useIsolates) {
      try {
        isolateManager.dispose();
      } catch (e) {
        // Ignore errors during dispose
      }
    }
    try {
      performanceMonitor.dispose();
    } catch (e) {
      // Ignore errors during dispose
    }
    try {
      if (!_logStreamController.isClosed) {
        _logStreamController.close();
      }
    } catch (e) {
      // Ignore errors during dispose
    }
    _isInitialized = false;
  }

  /// Prints initialization details of the logger, including whether it was a reconfiguration.
  void _printStrategicLoggerInit({bool isReconfiguration = false}) {
    final appName = _getAppName();

    // ASCII Art Banner
    final asciiArt = _generateAsciiArt(appName);

    String strategiesFormatted = _strategies
        .map((s) => '[HYPN-TECH]     └─ ${s.toString()}')
        .join('\n');

    final configType = isReconfiguration ? 'RECONFIGURATION' : 'CONFIGURATION';

    String logMessage = [
      asciiArt,
      '',
      '[HYPN-TECH] STRATEGIC LOGGER $configType',
      '[HYPN-TECH] Logger initialized successfully!',
      '[HYPN-TECH] CONFIGURATION:',
      '[HYPN-TECH]     • Log Level: $_initLogLevel',
      '[HYPN-TECH]     • Use Isolates: $_useIsolates',
      '[HYPN-TECH]     • Performance Monitoring: $_enablePerformanceMonitoring',
      '[HYPN-TECH]     • Modern Console: $_enableModernConsole',
      '[HYPN-TECH] ACTIVE STRATEGIES:',
      strategiesFormatted,
      '[HYPN-TECH] Platform: ${_isIsolateSupported() ? 'Isolates Supported' : 'Isolates Not Supported'}',
      '[HYPN-TECH] App: $appName',
    ].join('\n');

    // Log to console (terminal)
    print(logMessage);

    // Also log to DevTools
    developer.log(logMessage, name: 'StrategicLogger');

    // Also emit to stream for Live Console
    final initLogEntry = LogEntry(
      level: LogLevel.info,
      message: logMessage,
      timestamp: DateTime.now(),
    );
    if (!_logStreamController.isClosed) {
      _logStreamController.add(initLogEntry);
    }
  }

  /// Generates modern colored ASCII art banner for the logger initialization.
  ///
  /// Automatically detects if the terminal supports ANSI colors.
  /// On iOS/Android, returns plain text to avoid garbage like `\^[[36m`.
  String _generateAsciiArt(String appName) {
    // Check if terminal supports ANSI colors
    if (!TerminalCapabilities.supportsAnsiColors) {
      return _generatePlainAsciiArt(appName);
    }

    // ANSI color codes for gradient effect (cyan -> blue -> magenta)
    const reset = '\x1B[0m';
    const bold = '\x1B[1m';
    const cyan = '\x1B[36m';
    const blue = '\x1B[34m';
    const magenta = '\x1B[35m';
    const dim = '\x1B[2m';

    // Generate dynamic ASCII art for project name
    final asciiName = _generateAsciiText(appName.toUpperCase());
    final lines = asciiName.split('\n');

    // Apply gradient colors to each line
    final coloredLines = <String>[];
    final colors = [cyan, cyan, blue, magenta];
    for (int i = 0; i < lines.length; i++) {
      final color = colors[i % colors.length];
      coloredLines.add('$bold$color${lines[i]}$reset');
    }

    return '''

${coloredLines.join('\n')}

$dim  Strategic Logger powered by Hypn Tech (hypn.com.br)$reset''';
  }

  /// Generates plain ASCII art banner without colors for terminals that don't support ANSI.
  String _generatePlainAsciiArt(String appName) {
    final asciiName = _generateAsciiText(appName.toUpperCase());
    return '''

$asciiName

  Strategic Logger powered by Hypn Tech (hypn.com.br)''';
  }

  /// Generates ASCII art text from a string using a compact modern font
  String _generateAsciiText(String text) {
    // Compact 4-line ASCII font map
    const Map<String, List<String>> font = {
      'A': [' __ ', '|__|', '|  |', '    '],
      'B': ['___ ', '|__]', '|__]', '    '],
      'C': [' __ ', '|  ', '|__', '    '],
      'D': ['___ ', '|  \\', '|__/', '    '],
      'E': ['___ ', '|__ ', '|___', '    '],
      'F': ['___ ', '|__ ', '|   ', '    '],
      'G': [' __ ', '| _ ', '|__]', '    '],
      'H': ['    ', '|__|', '|  |', '    '],
      'I': ['___ ', ' |  ', '_|_ ', '    '],
      'J': ['  _ ', '  | ', '|_| ', '    '],
      'K': ['    ', '|_/ ', '| \\ ', '    '],
      'L': ['    ', '|   ', '|___', '    '],
      'M': ['    ', '|\\/|', '|  |', '    '],
      'N': ['    ', '|\\ |', '| \\|', '    '],
      'O': [' __ ', '|  |', '|__|', '    '],
      'P': ['___ ', '|__]', '|   ', '    '],
      'Q': [' __ ', '|  |', '|_\\|', '    '],
      'R': ['___ ', '|__/', '|  \\', '    '],
      'S': [' __ ', '[__ ', '___]', '    '],
      'T': ['___', ' | ', ' | ', '   '],
      'U': ['    ', '|  |', '|__|', '    '],
      'V': ['    ', '|  |', ' \\/ ', '    '],
      'W': ['    ', '|  |', '|/\\|', '    '],
      'X': ['    ', '\\_/ ', '/ \\ ', '    '],
      'Y': ['    ', '\\_/ ', ' |  ', '    '],
      'Z': ['___', ' / ', '/__', '   '],
      '0': [' _ ', '| |', '|_|', '   '],
      '1': ['   ', ' | ', ' | ', '   '],
      '2': [' _ ', ' _|', '|_ ', '   '],
      '3': ['__ ', ' _|', '__|', '   '],
      '4': ['   ', '|_|', '  |', '   '],
      '5': [' _ ', '|_ ', ' _|', '   '],
      '6': [' _ ', '|_ ', '|_|', '   '],
      '7': ['__ ', '  |', '  |', '   '],
      '8': [' _ ', '|_|', '|_|', '   '],
      '9': [' _ ', '|_|', ' _|', '   '],
      ' ': ['  ', '  ', '  ', '  '],
      '_': ['   ', '   ', '___', '   '],
      '-': ['   ', '___', '   ', '   '],
      '.': ['  ', '  ', '. ', '  '],
    };

    // Build 4 lines of ASCII art
    final line0 = StringBuffer();
    final line1 = StringBuffer();
    final line2 = StringBuffer();
    final line3 = StringBuffer();

    for (final char in text.split('')) {
      final charArt = font[char] ?? font[' ']!;
      line0.write(charArt[0]);
      line1.write(charArt[1]);
      line2.write(charArt[2]);
      line3.write(charArt[3]);
    }

    return '${line0.toString()}\n${line1.toString()}\n${line2.toString()}';
  }

  /// Gets the application name from initialization parameter or default
  String _getAppName() {
    // Use custom project name if provided during initialization
    if (_projectName != null && _projectName!.isNotEmpty) {
      // Ensure version starts with lowercase 'v' and has space before it
      final name = _projectName!;
      // Replace patterns like "AppName V1.0.0" or "AppName v1.0.0" with "AppName v1.0.0"
      return name.replaceAllMapped(
        RegExp(r'\s+[Vv](\d+\.\d+\.\d+)'),
        (match) => ' v${match.group(1)}',
      );
    }
    // Default to Strategic Logger if no project name provided
    return 'STRATEGIC LOGGER';
  }
}
