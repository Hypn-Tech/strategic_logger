# CLAUDE.md - Strategic Logger Development Guidelines

> **Core Principle**: "Call once, log all strategies" - One logging call dispatches to all configured destinations without impacting app performance.

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Architecture Guidelines](#2-architecture-guidelines)
3. [Simplification Roadmap](#3-simplification-roadmap-2026-best-practices)
4. [Strategy Development Guide](#4-strategy-development-guide)
5. [Testing Standards](#5-testing-standards)
6. [Anti-Patterns to Avoid](#6-anti-patterns-to-avoid)
7. [Performance Considerations](#7-performance-considerations)
8. [Breaking Changes Analysis](#8-breaking-changes-analysis)
9. [Quick Reference](#9-quick-reference)

---

## 1. Project Overview

### Core Concept

Strategic Logger implements the **Strategy Pattern** for logging in Dart/Flutter applications. Initialize once with multiple strategies, then every log call automatically dispatches to all destinations:

```dart
// Initialize once at app startup
await logger.initialize(
  strategies: [
    ConsoleLogStrategy(),
    SentryLogStrategy(),
    DatadogLogStrategy(apiKey: 'key', service: 'app', env: 'prod'),
  ],
);

// One call logs to Console + Sentry + Datadog simultaneously
await logger.info('User logged in', context: {'userId': '123'});
```

### Package Structure

```
lib/
  logger.dart                    # Main public export
  logger_extension.dart          # Extension exports
  src/
    strategic_logger.dart        # Core StrategicLogger class + global `logger`
    enums/
      log_level.dart             # LogLevel enum (debug, info, warning, error, fatal)
    events/
      log_event.dart             # LogEvent base class
    core/
      log_queue.dart             # LogEntry class + async queue
      isolate_manager.dart       # [Internal] Isolate processing
      performance_monitor.dart   # [Internal] Metrics tracking
      object_pool.dart           # [Deprecated] Unused
      log_compression.dart       # [Deprecated] Unused
    strategies/
      log_strategy.dart          # Abstract base class
      console/                   # Console output strategy
      sentry/                    # Sentry integration
      analytics/                 # Firebase Analytics
      crashlytics/               # Firebase Crashlytics
      datadog/                   # Datadog HTTP strategy
      newrelic/                  # New Relic HTTP strategy
    mcp/                         # [Deprecated] MCP server - scope creep
    ai/                          # [Deprecated] AI analysis - scope creep
```

### Key Entry Points

| File | Purpose |
|------|---------|
| `lib/logger.dart` | Main import for consumers |
| `lib/src/strategic_logger.dart` | `StrategicLogger` class + global `logger` instance |
| `lib/src/strategies/log_strategy.dart` | Base class all strategies extend |
| `lib/src/core/log_queue.dart` | `LogEntry` data class |

---

## 2. Architecture Guidelines

### The Strategy Pattern Contract

All strategies extend `LogStrategy` (see `lib/src/strategies/log_strategy.dart`):

```dart
abstract class LogStrategy {
  LogLevel logLevel;
  LogLevel loggerLogLevel;
  List<LogEvent>? supportedEvents;

  // Primary interface (v1.4.0+) - implement these
  Future<void> log(LogEntry entry);
  Future<void> info(LogEntry entry);
  Future<void> error(LogEntry entry);
  Future<void> fatal(LogEntry entry);

  // Legacy interface - still works for backward compatibility
  Future<void> logMessage(dynamic message, LogEvent? event, Map<String, dynamic>? context);
  Future<void> logError(dynamic error, StackTrace? stackTrace, LogEvent? event, Map<String, dynamic>? context);

  bool shouldLog({LogEvent? event});  // Filtering logic
}
```

### LogEntry - The Complete Data Package

All log data travels in `LogEntry` (defined in `lib/src/core/log_queue.dart`):

```dart
class LogEntry {
  final dynamic message;
  final LogLevel level;
  final DateTime timestamp;
  final LogEvent? event;
  final Map<String, dynamic>? context;  // CRITICAL: Always propagate
  final StackTrace? stackTrace;
}
```

### Context Propagation - CRITICAL PATTERN

Context MUST flow to ALL strategies. Currently duplicated 12+ times:

```dart
// Current pattern (duplicated in every strategy)
final mergedContext = <String, dynamic>{};
if (entry.context != null) mergedContext.addAll(entry.context!);
if (entry.event?.parameters != null) mergedContext.addAll(entry.event!.parameters!);
```

### Dispatch Flow

```
logger.info('msg', context: {...})
  └─> LogEntry.fromParams()
       └─> LogQueue.enqueue()
            └─> Stream listener
                 └─> _processLogEntry()
                      └─> for each strategy: _executeStrategy()
                           └─> strategy.info(entry)
```

### What Stays Internal

These should NOT be used directly by consumers:
- `IsolateManager` - Internal optimization detail
- `PerformanceMonitor` - Internal metrics
- `LogQueue` - Internal (but `LogEntry` is public)

---

## 3. Simplification Roadmap (2026 Best Practices)

### REMOVE: Unused Code

#### ObjectPool (`lib/src/core/object_pool.dart`) - 452 lines

**Problem**: Exported but NEVER used anywhere in the codebase.

```dart
// In lib/logger.dart line 111 - exported but never initialized or called
export 'src/core/object_pool.dart' hide LogEvent;
```

**Action**: Mark `@Deprecated` in v1.5.0, remove in v2.0.0

#### LogCompression (`lib/src/core/log_compression.dart`) - 508 lines

**Problem**: Exported but never integrated into StrategicLogger initialization.

**Action**: Mark `@Deprecated` in v1.5.0, remove in v2.0.0

#### IsolateManager in Console Formatting

**Problem**: Isolates used only for simple string formatting - overhead exceeds benefit.

```dart
// In console_log_strategy.dart - isolate overhead for simple formatting
final formattedMessage = await isolateManager.runInIsolate(
  _formatLogMessage,  // Just string concatenation
  {'message': message, 'level': level},
);
```

**Action**: Remove isolate call, format directly. Keep IsolateManager infrastructure for genuine heavy operations.

---

### CONSOLIDATE: Duplicated Patterns

#### Context Merging Helper

**Current**: Duplicated 12+ times across strategies:

```dart
// In SentryLogStrategy, DatadogLogStrategy, ConsoleLogStrategy, etc.
final context = <String, dynamic>{};
if (entry.context != null) context.addAll(entry.context!);
if (entry.event?.parameters != null) context.addAll(entry.event!.parameters!);
```

**Solution**: Add getter to LogEntry class:

```dart
// In lib/src/core/log_queue.dart - add to LogEntry class
class LogEntry {
  // ... existing fields ...

  /// Merges context from entry and event parameters
  Map<String, dynamic> get mergedContext {
    final result = <String, dynamic>{};
    if (context != null) result.addAll(context!);
    if (event?.parameters != null) result.addAll(event!.parameters!);
    return result;
  }
}
```

#### HTTP Strategy Base Class

**Current**: DatadogLogStrategy (353 lines) and NewRelicLogStrategy (251 lines) duplicate:
- HttpClient setup
- Batch processing (`_batch`, `_batchTimer`, `_batchTimeout`)
- Retry logic (`_sendBatchWithRetry`)
- dispose() pattern

**Solution**: Extract base class:

```dart
// lib/src/strategies/http_log_strategy.dart (NEW FILE)
abstract class HttpLogStrategy extends LogStrategy {
  final HttpClient _httpClient = HttpClient();
  final List<Map<String, dynamic>> _batch = [];
  Timer? _batchTimer;

  // Configuration
  int get batchSize => 100;
  Duration get batchTimeout => const Duration(seconds: 5);
  int get maxRetries => 3;

  // Abstract - implement in subclasses
  String get endpoint;
  Map<String, String> get headers;
  Map<String, dynamic> formatLogEntry(LogEntry entry);

  // Shared implementation
  Future<void> sendBatchWithRetry(List<Map<String, dynamic>> batch) async {
    // Common retry logic here
  }

  void dispose() {
    _batchTimer?.cancel();
    _httpClient.close();
    if (_batch.isNotEmpty) _flushBatch();
  }
}
```

---

### SIMPLIFY: StrategicLogger Class

#### Current Issues

The `StrategicLogger` class in `lib/src/strategic_logger.dart` has:
- 713 lines total
- 25+ public methods
- 12 logging methods (log, info, error, fatal + Sync variants + aliases)
- 72-line `_initialize()` method mixing multiple concerns

#### Simplification Options

**Option 1**: Reduce logging methods (v2.0.0)

```dart
// Current: 12 methods
logger.log(), logger.info(), logger.error(), logger.fatal()
logger.debug(), logger.warning(), logger.verbose()
logger.logSync(), logger.infoSync(), logger.errorSync(), logger.fatalSync()
logger.verboseSync()

// Simplified: Keep async methods, deprecate Sync variants
// Sync methods are just fire-and-forget wrappers anyway
```

**Option 2**: Extract initialization (internal refactor)

```dart
// Current: 72-line _initialize() method
// Split into focused methods:
Future<void> _initialize() async {
  _validateNotAlreadyInitialized();
  _cleanupIfForced();
  _initializeFeatures();
  _initializeStrategies(strategies, level);
  _isInitialized = true;
  _printInitBanner();
}
```

---

## 4. Strategy Development Guide

### Creating a New Strategy

#### Step 1: Extend LogStrategy

```dart
// lib/src/strategies/custom/custom_log_strategy.dart
import '../log_strategy.dart';
import '../../core/log_queue.dart';
import '../../enums/log_level.dart';

class CustomLogStrategy extends LogStrategy {
  final String apiKey;

  CustomLogStrategy({
    required this.apiKey,
    super.logLevel = LogLevel.none,
    super.supportedEvents,
  });

  @override
  Future<void> log(LogEntry entry) async => _processEntry(entry);

  @override
  Future<void> info(LogEntry entry) async => _processEntry(entry);

  @override
  Future<void> error(LogEntry entry) async => _processEntry(entry);

  @override
  Future<void> fatal(LogEntry entry) async => _processEntry(entry);

  Future<void> _processEntry(LogEntry entry) async {
    if (!shouldLog(event: entry.event)) return;

    // Merge context (use mergedContext getter after simplification)
    final context = <String, dynamic>{};
    if (entry.context != null) context.addAll(entry.context!);
    if (entry.event?.parameters != null) context.addAll(entry.event!.parameters!);

    // Your implementation
    await _sendToService({
      'message': entry.message.toString(),
      'level': entry.level.name,
      'timestamp': entry.timestamp.toIso8601String(),
      'context': context,
    });
  }
}
```

#### Step 2: Handle Errors Gracefully

```dart
import 'dart:developer' as developer;

Future<void> _processEntry(LogEntry entry) async {
  try {
    // Implementation
  } catch (e, stack) {
    developer.log(
      'Error in CustomLogStrategy: $e',
      name: 'CustomLogStrategy',
      error: e,
      stackTrace: stack,
    );
    // NEVER rethrow - other strategies must still execute
  }
}
```

#### Step 3: Implement dispose() for Resources

```dart
void dispose() {
  _timer?.cancel();
  _httpClient.close();
  // Flush pending logs if applicable
}
```

### Strategy Checklist

- [ ] Extends `LogStrategy`
- [ ] Overrides all four methods: `log`, `info`, `error`, `fatal`
- [ ] Uses `shouldLog(event: entry.event)` check
- [ ] Merges context from `entry.context` AND `entry.event?.parameters`
- [ ] Handles errors with try-catch, logs to `developer.log`
- [ ] NEVER throws exceptions that would break other strategies
- [ ] Implements `dispose()` if using resources (HttpClient, Timer, Stream)
- [ ] Uses `@override` annotation
- [ ] Has dartdoc comments on public API

### HTTP Strategy Template

For strategies sending to HTTP endpoints, follow DatadogLogStrategy pattern:

```dart
class HttpCustomStrategy extends LogStrategy {
  final HttpClient _httpClient = HttpClient();
  final List<Map<String, dynamic>> _batch = [];
  Timer? _batchTimer;

  final int batchSize;
  final Duration batchTimeout;

  HttpCustomStrategy({
    required String apiKey,
    this.batchSize = 100,
    this.batchTimeout = const Duration(seconds: 5),
  }) {
    _startBatchTimer();
  }

  void _startBatchTimer() {
    _batchTimer = Timer.periodic(batchTimeout, (_) {
      if (_batch.isNotEmpty) _sendBatch();
    });
  }

  @override
  Future<void> log(LogEntry entry) async {
    _batch.add(_formatEntry(entry));
    if (_batch.length >= batchSize) await _sendBatch();
  }

  Future<void> _sendBatch() async {
    final batch = List<Map<String, dynamic>>.from(_batch);
    _batch.clear();
    await _sendWithRetry(batch);
  }

  void dispose() {
    _batchTimer?.cancel();
    _httpClient.close();
    if (_batch.isNotEmpty) _sendBatch();  // Flush remaining
  }
}
```

---

## 5. Testing Standards

### Test File Organization

```
test/
  strategic_logger_test.dart      # Core logger unit tests
  context_propagation_test.dart   # Context flow verification
  all_strategies_test.dart        # Multi-strategy integration
  [strategy]_test.dart            # Individual strategy tests
  performance_test.dart           # Performance benchmarks
  integration_test.dart           # End-to-end tests
```

### Running Tests

```bash
# All tests
flutter test

# Specific test file
flutter test test/strategic_logger_test.dart

# With coverage
flutter test --coverage

# Dart-only tests (no Flutter)
dart test test/dart_only_test.dart
```

### Test Patterns

#### Strategy Test Pattern

```dart
import 'package:test/test.dart';
import 'package:strategic_logger/src/core/log_queue.dart';
import 'package:strategic_logger/src/enums/log_level.dart';

void main() {
  group('CustomLogStrategy', () {
    late CustomLogStrategy strategy;

    setUp(() {
      strategy = CustomLogStrategy(apiKey: 'test-key');
    });

    tearDown(() {
      strategy.dispose();
    });

    test('should process log entry with context', () async {
      final entry = LogEntry.fromParams(
        message: 'Test message',
        level: LogLevel.info,
        context: {'userId': '123'},
      );

      await strategy.log(entry);

      // Verify behavior
    });

    test('should handle errors gracefully', () async {
      // Strategy errors should NOT throw
      expect(
        () => strategy.log(LogEntry.fromParams(
          message: null,  // Edge case
          level: LogLevel.error,
        )),
        returnsNormally,
      );
    });
  });
}
```

#### Context Propagation Test Pattern

```dart
test('context should propagate from entry and event', () async {
  final entry = LogEntry.fromParams(
    message: 'Test',
    level: LogLevel.info,
    context: {'entryKey': 'entryValue'},
    event: LogEvent(
      eventName: 'test_event',
      parameters: {'eventKey': 'eventValue'},
    ),
  );

  expect(entry.context!['entryKey'], equals('entryValue'));
  expect(entry.event!.parameters!['eventKey'], equals('eventValue'));

  // After mergedContext getter is added:
  // expect(entry.mergedContext['entryKey'], equals('entryValue'));
  // expect(entry.mergedContext['eventKey'], equals('eventValue'));
});
```

#### Logger Integration Test Pattern

```dart
group('Logger Integration', () {
  late StrategicLogger testLogger;

  setUp(() {
    testLogger = StrategicLogger();
  });

  tearDown(() {
    testLogger.dispose();
  });

  test('should initialize with strategies', () async {
    await testLogger.initialize(
      strategies: [ConsoleLogStrategy()],
      level: LogLevel.debug,
      force: true,  // IMPORTANT for test isolation
    );

    expect(testLogger.isInitialized, isTrue);
  });
});
```

### PR Test Requirements

- [ ] All existing tests pass
- [ ] New code has corresponding tests
- [ ] Context propagation verified for new strategies
- [ ] Error handling tested (no exceptions leak)
- [ ] dispose() cleanup verified for resource-holding classes
- [ ] Performance tests pass within bounds

---

## 6. Anti-Patterns to Avoid

### 1. Premature Optimization

**Example from codebase**: `ObjectPool` (452 lines) was never used.

```dart
// lib/src/core/object_pool.dart - 452 lines of unused code
class ObjectPool<T> {
  final List<T> _pool = [];
  int _created = 0;
  int _reused = 0;
  // ... elaborate implementation never called
}
```

**Lesson**: Don't optimize until you have:
- Measured the actual problem
- Proven the optimization helps
- Justified the maintenance cost

### 2. Scope Creep

**Example from codebase**: MCP Server (HTTP server in a logging library) and AI Strategy (external API calls).

```dart
// lib/src/mcp/mcp_server.dart - starts HTTP server
// lib/src/ai/ai_log_strategy.dart - 584 lines calling external AI APIs
```

**Lesson**: A logging library should:
- Accept log entries
- Format and dispatch to destinations
- NOT run servers, make AI calls, or add tangential features

**Solution**: Move to separate packages (`strategic_logger_mcp`, `strategic_logger_ai`)

### 3. Interface Bloat

**Example from codebase**: `LogStrategy` forces 6 method implementations when most strategies only need 1-2 different behaviors.

```dart
// Most strategies do this:
@override Future<void> log(LogEntry e) => _process(e);
@override Future<void> info(LogEntry e) => _process(e);
@override Future<void> error(LogEntry e) => _process(e);
@override Future<void> fatal(LogEntry e) => _process(e);
```

**Better pattern** (consider for v2.0):
```dart
abstract class LogStrategy {
  Future<void> process(LogEntry entry);

  // Default implementations call process()
  Future<void> log(LogEntry e) => process(e);
  Future<void> info(LogEntry e) => process(e);
  Future<void> error(LogEntry e) => process(e);
  Future<void> fatal(LogEntry e) => process(e);
}
```

### 4. Code Duplication

**Example from codebase**: Context merging duplicated 12+ times.

```dart
// Found in: SentryLogStrategy, DatadogLogStrategy, NewRelicLogStrategy,
// ConsoleLogStrategy, FirebaseAnalyticsLogStrategy, FirebaseCrashlyticsLogStrategy, etc.
final context = <String, dynamic>{};
if (entry.context != null) context.addAll(entry.context!);
if (entry.event?.parameters != null) context.addAll(entry.event!.parameters!);
```

**Solution**: Extract to shared method or LogEntry getter.

### 5. Long Methods

**Example from codebase**: `_initialize()` is 72 lines with multiple responsibilities.

```dart
// lib/src/strategic_logger.dart lines 143-215
Future<StrategicLogger> _initialize({...}) async {
  // Validation (should be separate)
  if (_isInitialized && !force) throw AlreadyInitializedError();

  // Cleanup (should be separate)
  if (_isInitialized && force) {
    try { _logQueue?.dispose(); } catch (e) { /* ignore */ }
    try { isolateManager.dispose(); } catch (e) { /* ignore */ }
    // ... 20+ more lines of cleanup
  }

  // Initialization (should be separate)
  if (!_isInitialized) {
    // ... 30+ lines
  }

  return logger;
}
```

**Solution**: Extract into focused methods.

### 6. Inconsistent Dispatch

**Example from codebase**: `_executeStrategy` uses switch with inconsistent method mapping.

```dart
// lib/src/strategic_logger.dart lines 260-291
switch (entry.level) {
  case LogLevel.debug:
    await strategy.log(entry);    // debug -> log()
  case LogLevel.info:
    await strategy.info(entry);   // info -> info()
  case LogLevel.warning:
    await strategy.log(entry);    // warning -> log() (inconsistent!)
  // ...
}
```

**Issue**: Why does `debug` call `log()` but `info` calls `info()`?

---

## 7. Performance Considerations

### When Isolates Make Sense

**Use isolates for**:
- JSON serialization of large payloads (1000+ entries)
- Compression of batch logs before HTTP send
- Heavy data transformations

**Do NOT use isolates for**:
- Simple string formatting (current console strategy misuse)
- Operations under 10ms
- Single log entry processing

### Batch Processing Guidelines

HTTP strategies should batch to reduce network overhead:

```dart
final int batchSize = 100;           // Force send after N entries
final Duration batchTimeout = 5s;    // Force send after N seconds
```

### Queue Backpressure

LogQueue handles high volume by dropping oldest entries:

```dart
// In lib/src/core/log_queue.dart
if (_queue.length >= _maxSize) {
  _queue.removeFirst();  // Drop oldest
}
_queue.add(entry);
```

Default: `maxSize = 1000` entries

### Performance Testing

```dart
test('should handle 1000 logs efficiently', () async {
  final stopwatch = Stopwatch()..start();

  for (int i = 0; i < 1000; i++) {
    await logger.info('Log $i');
  }

  stopwatch.stop();
  expect(stopwatch.elapsedMilliseconds, lessThan(1000));
});
```

---

## 8. Breaking Changes Analysis

### Public API (lib/logger.dart exports)

| Export | Status | Breaking if Removed? |
|--------|--------|---------------------|
| `StrategicLogger`, `logger` | Core | YES - never remove |
| `LogLevel` enum | Core | YES - never remove |
| `LogEvent` class | Core | YES - never remove |
| `LogStrategy` abstract | Core | YES - never remove |
| All Strategy classes | Core | YES - never remove |
| `ObjectPool` | Unused | LOW - not integrated |
| `LogCompression` | Unused | LOW - not integrated |
| `MCPLogStrategy` | Scope creep | MEDIUM - advanced users |
| `AILogStrategy` | Scope creep | MEDIUM - advanced users |

### Versioning Strategy

```
v1.5.0 - Deprecation Release (NO breaking changes)
  - @Deprecated on ObjectPool, LogCompression, MCP, AI
  - Add LogEntry.mergedContext getter
  - Internal refactoring (HttpLogStrategy base)
  - Add CLAUDE.md

v2.0.0 - Cleanup Release (BREAKING)
  - Remove deprecated exports
  - Move MCP/AI to separate packages
  - Simplify internal code
```

### Deprecation Example

```dart
// In lib/logger.dart
@Deprecated('ObjectPool is unused internally. Will be removed in v2.0.0')
export 'src/core/object_pool.dart' hide LogEvent;

@Deprecated('LogCompression is unused internally. Will be removed in v2.0.0')
export 'src/core/log_compression.dart';

@Deprecated('Use package:strategic_logger_mcp instead. Will be removed in v2.0.0')
export 'src/mcp/mcp_log_strategy.dart';

@Deprecated('Use package:strategic_logger_ai instead. Will be removed in v2.0.0')
export 'src/ai/ai_log_strategy.dart';
```

### Impact Assessment

- **ObjectPool removal**: ~0 users impacted (never integrated)
- **LogCompression removal**: ~0 users impacted (never integrated)
- **MCP/AI removal**: Low impact (advanced features, separate packages available)
- **Core API**: NO changes planned

---

## 9. Quick Reference

### Build & Test Commands

```bash
# Install dependencies
flutter pub get

# Run all tests
flutter test

# Run specific test
flutter test test/strategic_logger_test.dart

# Analyze code
flutter analyze

# Format code
dart format lib test

# Check pub score
flutter pub publish --dry-run
```

### Critical Files

| File | Lines | Purpose |
|------|-------|---------|
| `lib/src/strategic_logger.dart` | 713 | Core logger (target for simplification) |
| `lib/src/strategies/log_strategy.dart` | ~100 | Base class for all strategies |
| `lib/src/core/log_queue.dart` | ~170 | LogEntry class + queue |
| `lib/src/strategies/datadog/datadog_log_strategy.dart` | 353 | HTTP strategy reference impl |
| `lib/logger.dart` | 115 | Public exports |

### Common Patterns

```dart
// Initialize logger
await logger.initialize(
  strategies: [ConsoleLogStrategy()],
  level: LogLevel.debug,
);

// Log with context
await logger.info('Message', context: {'key': 'value'});

// Log error with stack trace
await logger.error('Failed', stackTrace: StackTrace.current);

// Check initialization
if (logger.isInitialized) { ... }

// Flush pending logs
logger.flush();

// Clean up
logger.dispose();
```

### Strategy Quick Reference

| Strategy | Import | Key Config |
|----------|--------|------------|
| Console | `ConsoleLogStrategy` | `useModernFormatting`, `useColors` |
| Sentry | `SentryLogStrategy` | DSN configured externally |
| Firebase Analytics | `FirebaseAnalyticsLogStrategy` | Firebase configured externally |
| Firebase Crashlytics | `FirebaseCrashlyticsLogStrategy` | Firebase configured externally |
| Datadog | `DatadogLogStrategy` | `apiKey`, `service`, `env` |
| New Relic | `NewRelicLogStrategy` | `licenseKey`, `appName` |

---

## Contributing

1. Read this CLAUDE.md thoroughly
2. Check [Simplification Roadmap](#3-simplification-roadmap-2026-best-practices) before adding complexity
3. Follow [Strategy Development Guide](#4-strategy-development-guide) for new strategies
4. Avoid [Anti-Patterns](#6-anti-patterns-to-avoid)
5. Include tests per [Testing Standards](#5-testing-standards)
6. Consider [Breaking Changes](#8-breaking-changes-analysis) for public API changes

---

*Last updated: 2026-01-08*
*Maintainer: Hypn Tech (hypn.com.br)*
