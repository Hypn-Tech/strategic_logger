# Strategic Logger

```
 __ ______  __ ______  __ ___  __        __  __  __ ___ ___
[__  | |__/|__| | |__ | _  |  |    |   |  || _ | _ |__ |__/
___] | |  \|  | | |___|__]_|_ |__  |___|__||__]|__]|___|  \

  Strategic Logger powered by Hypn Tech (hypn.com.br)
```

<div align="center">

[![Pub Version](https://img.shields.io/pub/v/strategic_logger?style=for-the-badge)](https://pub.dev/packages/strategic_logger)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev/)

**One call, all strategies. Enterprise logging for Flutter.**

</div>

---

## Quick Start

```dart
import 'package:strategic_logger/logger.dart';

// Works immediately - no initialization needed
logger.info('App started');
logger.debug('Debug details', context: {'version': '4.0.0'});
logger.error('Something failed', stackTrace: StackTrace.current);
```

Output:

```
14:30:25.123 [INFO ] App started
14:30:25.124 [DEBUG] Debug details
[CONTEXT]
   version: 4.0.0
14:30:25.125 [ERROR] Something failed
Stack Trace: ...
```

## Full Configuration

```dart
import 'package:strategic_logger/logger.dart';

void main() async {
  await logger.initialize(
    projectName: 'My App',
    level: LogLevel.info,
    strategies: [
      ConsoleLogStrategy(useModernFormatting: true, useColors: true),
      SentryLogStrategy(),
      FirebaseCrashlyticsLogStrategy(),
      DatadogLogStrategy(apiKey: 'key', service: 'app', env: 'prod'),
    ],
  );

  // One call logs to Console + Sentry + Crashlytics + Datadog
  logger.info('User logged in', context: {'userId': '123'});
}
```

---

## Built-in Strategies

| Strategy | Use Case | Key Config |
|----------|----------|------------|
| `ConsoleLogStrategy` | Development & debugging | `useModernFormatting`, `useColors` |
| `FirebaseAnalyticsLogStrategy` | User behavior tracking | Firebase configured externally |
| `FirebaseCrashlyticsLogStrategy` | Crash reports in production | Firebase configured externally |
| `SentryLogStrategy` | Error monitoring with context | DSN configured externally |
| `DatadogLogStrategy` | APM & centralized logs | `apiKey`, `service`, `env` |
| `NewRelicLogStrategy` | Performance monitoring | `licenseKey`, `appName` |

### Decision Matrix: When to Use Each Strategy

| Scenario | Recommended Strategy | Why |
|----------|---------------------|-----|
| Local development | `ConsoleLogStrategy` | Beautiful colored output, zero config |
| User analytics | `FirebaseAnalyticsLogStrategy` | Track events, conversions, behavior |
| Crash tracking | `FirebaseCrashlyticsLogStrategy` | Non-fatal and fatal crash reports |
| Error monitoring | `SentryLogStrategy` | Rich error context, breadcrumbs |
| Full observability | `DatadogLogStrategy` | APM, logs, metrics in one platform |
| Performance monitoring | `NewRelicLogStrategy` | Application performance insights |
| Custom destination | Extend `LogStrategy` or `HttpLogStrategy` | Full control over log routing |

---

## Features

### Named Loggers

Organize logs by module or component:

```dart
final authLogger = logger.named('auth');
final paymentLogger = logger.named('payment');

authLogger.info('User logged in');      // [auth] User logged in
paymentLogger.error('Payment failed');  // [payment] Payment failed
```

### Lazy Evaluation

Avoid expensive computations when log level is inactive:

```dart
// Always evaluates (even if debug is disabled)
logger.debug('Users: ${expensiveQuery()}');

// Only evaluates if the message is actually logged
logger.debug(() => 'Users: ${expensiveQuery()}');
```

### Stream Listeners

Listen to log entries for custom processing:

```dart
logger.listen((entry) {
  myAnalytics.track(entry.message, entry.mergedContext);
});
```

### Shorthand Aliases

Concise logging inspired by the `logger` package:

```dart
logger.d('Debug');    // Same as logger.debug()
logger.i('Info');     // Same as logger.info()
logger.w('Warning');  // Same as logger.warning()
logger.e('Error');    // Same as logger.error()
logger.f('Fatal');    // Same as logger.fatal()
```

### Structured Logging with Context

Context is passed to ALL strategies automatically:

```dart
logger.info('User action', context: {
  'userId': '123',
  'action': 'login',
  'device': 'iPhone 15',
});

// Context available in Datadog for indexing, Sentry as extra fields,
// Firebase Analytics as parameters, console as formatted output.
```

### Real-time Log Streaming

```dart
logger.logStream.listen((logEntry) {
  updateDashboard(logEntry);
});
```

---

## Creating Custom Strategies

### Simple: Override `handleLog()` (1 method)

```dart
import 'package:strategic_logger/logger.dart';

class MyCustomStrategy extends LogStrategy {
  @override
  Future<void> handleLog(LogEntry entry) async {
    if (!shouldLog(event: entry.event)) return;
    final context = entry.mergedContext;
    await sendToMyService(entry.message, context);
  }
}
```

### Per-Level: Override individual methods

```dart
class MyDetailedStrategy extends LogStrategy {
  @override
  Future<void> info(LogEntry entry) async {
    // Handle info differently
  }

  @override
  Future<void> error(LogEntry entry) async {
    // Handle errors differently
  }
}
```

### HTTP Strategy: Extend `HttpLogStrategy`

For strategies that send to HTTP endpoints, get batch processing, retry logic, and resource management for free:

```dart
class MyHttpStrategy extends HttpLogStrategy {
  final String apiKey;

  MyHttpStrategy({required this.apiKey})
      : super(batchSize: 50, batchTimeout: Duration(seconds: 10));

  @override
  String get strategyName => 'MyHttpStrategy';

  @override
  String get endpoint => 'https://api.example.com/logs';

  @override
  Map<String, String> get headers => {'Authorization': 'Bearer $apiKey'};

  @override
  Map<String, dynamic> formatLogEntry(LogEntry entry) => {
    'message': entry.message.toString(),
    'level': entry.level.name,
    'context': entry.mergedContext,
  };
}
```

---

## Strategy Configuration

### ConsoleLogStrategy

```dart
ConsoleLogStrategy(
  logLevel: LogLevel.debug,
  useModernFormatting: true,  // Rich formatting with colors
  useColors: true,            // Enable ANSI colors
  autoDetectColors: true,     // iOS/Android safe (no ANSI garbage)
  showTimestamp: true,
  showContext: true,
)
```

### DatadogLogStrategy

```dart
DatadogLogStrategy(
  apiKey: 'your-api-key',
  service: 'my-app',
  env: 'production',
  enableCompression: true,    // Gzip compression (default)
  batchSize: 100,             // Send after 100 entries
  batchTimeout: Duration(seconds: 5),  // Or after 5 seconds
  maxRetries: 3,              // Retry failed batches
)
```

### NewRelicLogStrategy

```dart
NewRelicLogStrategy(
  licenseKey: 'your-license-key',
  appName: 'my-app',
  batchSize: 50,
  batchTimeout: Duration(seconds: 10),
)
```

### Firebase Strategies

```dart
FirebaseAnalyticsLogStrategy(logLevel: LogLevel.info)
FirebaseCrashlyticsLogStrategy(logLevel: LogLevel.error)
```

### SentryLogStrategy

```dart
SentryLogStrategy(logLevel: LogLevel.error)
```

---

## Flutter App Integration

```dart
import 'package:flutter/material.dart';
import 'package:strategic_logger/logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await logger.initialize(
    projectName: 'My App',
    strategies: [
      ConsoleLogStrategy(useModernFormatting: true),
      FirebaseCrashlyticsLogStrategy(),
    ],
  );

  runApp(const MyApp());
}
```

---

## Performance

- **Synchronous API** - Logging calls return immediately (fire-and-forget)
- **Isolate-based processing** - Heavy operations run in background isolates
- **Batch processing** - HTTP strategies batch logs (100 entries or 5s timeout)
- **Async queue** - Backpressure control with 1000-entry buffer
- **Retry logic** - Exponential backoff for failed network operations

```dart
final stats = logger.getPerformanceStats();
```

---

## Troubleshooting

### ANSI colors showing as garbage on iOS/Android

Colors are auto-detected and disabled on platforms that don't support ANSI. If you still see issues:

```dart
ConsoleLogStrategy(autoDetectColors: true)  // Default - auto-detect
ConsoleLogStrategy(useColors: false)         // Force disable
```

### Isolates not working on Web

Isolates are automatically disabled on web platform. No configuration needed.

### HTTP strategy batch delays

Logs are batched for efficiency. To flush immediately:

```dart
logger.flush();
```

### Auto-init warning on startup

If you see the auto-initialization warning, call `initialize()` explicitly:

```dart
await logger.initialize(strategies: [ConsoleLogStrategy()]);
```

---

## Migration Guide

### From v3.x to v4.0.0

v4.0.0 is backward compatible. New features are additive:

- **`handleLog()`** - New single-method override for custom strategies (optional, old `log`/`info`/`error`/`fatal` overrides still work)
- **`logger.named('module')`** - Named loggers for organizing by component
- **`logger.debug(() => 'lazy')`** - Lazy evaluation support
- **`logger.listen()`** - Stream-based extensibility
- **`logger.d()`, `i()`, `w()`, `e()`, `f()`** - Shorthand aliases
- **`HttpLogStrategy`** - Base class for HTTP strategies
- **`LogEntry`** - Now exported from main `logger.dart`

### From v2.x to v3.0.0

```dart
// v2.x - required await
await logger.info('message');

// v3.0.0+ - synchronous, no await
logger.info('message');
```

See [CHANGELOG.md](CHANGELOG.md) for full version history.

---

## API Reference

### LogEntry

```dart
class LogEntry {
  final dynamic message;
  final LogLevel level;
  final DateTime timestamp;
  final LogEvent? event;
  final Map<String, dynamic>? context;
  final StackTrace? stackTrace;

  /// Merges context and event.parameters into one map
  Map<String, dynamic> get mergedContext;
}
```

### LogStrategy

```dart
abstract class LogStrategy {
  Future<void> handleLog(LogEntry entry);  // Override this (recommended)
  Future<void> log(LogEntry entry);        // Or override per-level
  Future<void> info(LogEntry entry);
  Future<void> error(LogEntry entry);
  Future<void> fatal(LogEntry entry);
  bool shouldLog({LogEvent? event});
}
```

---

## Supported Platforms

- Android, iOS, Web, macOS, Linux, Windows

---

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Read [CLAUDE.md](CLAUDE.md) for development guidelines
4. Run `flutter test` and `flutter analyze`
5. Open a Pull Request

---

<div align="center">

**Sponsored by [Hypn Tech](https://hypn.com.br)** - *Building the future of mobile applications*

[![GitHub](https://img.shields.io/badge/GitHub-100000?style=for-the-badge&logo=github&logoColor=white)](https://github.com/Hypn-Tech/strategic_logger)
[![Pub](https://img.shields.io/badge/Pub-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://pub.dev/packages/strategic_logger)

**MIT License** - See [LICENSE](LICENSE) for details.

</div>
