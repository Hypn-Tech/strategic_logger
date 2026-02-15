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

**Modern, high-performance logging framework for Flutter & Dart applications**

</div>

---

<div align="center">

## Sponsored by Hypn Tech

[![Hypn Tech](https://hypn.com.br/wp-content/uploads/2024/05/marca-hypn-institucional-1536x738.png)](https://hypn.com.br)

**Strategic Logger is proudly sponsored and maintained by [Hypn Tech](https://hypn.com.br)**

*Desenvolva seu app com a Hypn Tech - Soluções completas em desenvolvimento mobile e web*

</div>

---

## Why Strategic Logger?

### One Call, All Strategies
Log once and send to multiple destinations simultaneously - Console, Firebase, Sentry, Datadog, New Relic.

### Zero Configuration Required (v3.0.0)
- **Auto-initialization** - Works out of the box, no setup needed
- **Synchronous API** - No `await` required, just call `logger.info('msg')`
- **Fire-and-forget** - Logging never blocks your app

### Performance First
- **Isolate-based processing** - Never block the main thread
- **Async queue with backpressure** - Handle high log volumes efficiently
- **Batch processing** - Automatic batching for network strategies
- **Smart retry logic** - Exponential backoff for failed operations

### Beautiful Console Output
- **Auto-detect terminal capabilities** - iOS/Android safe, no ANSI garbage
- **Modern formatting** with colors and structured layout
- **Rich context display** with metadata and stack traces
- **Dynamic project banners** - Your app name in ASCII art

### Enterprise-Ready Integrations
- **Firebase Analytics & Crashlytics** - Complete Firebase suite support
- **Sentry** - Full error tracking integration
- **Datadog** - APM and log management
- **New Relic** - Application monitoring
- **Custom strategies** - Extend with your own logging destinations

---

## Quick Start

### Installation

Add Strategic Logger to your `pubspec.yaml`:

```yaml
dependencies:
  strategic_logger: ^3.0.0
```

Then run:
```bash
flutter pub get
```

### Zero-Config Usage (NEW in v3.0.0)

```dart
import 'package:strategic_logger/logger.dart';

void main() {
  // Just use it! No initialization needed.
  // Auto-initializes with ConsoleLogStrategy at debug level.
  logger.info('App started');
  logger.debug('Debug details', context: {'version': '3.0.0'});
  logger.error('Something failed', stackTrace: StackTrace.current);
}
```

### Full Configuration (Recommended for Production)

```dart
import 'package:strategic_logger/logger.dart';

void main() async {
  // Initialize with your preferred strategies
  await logger.initialize(
    projectName: 'My App',  // Your project name appears in the banner!
    level: LogLevel.info,
    strategies: [
      ConsoleLogStrategy(
        useModernFormatting: true,
        useColors: true,
      ),
      FirebaseAnalyticsLogStrategy(),
      FirebaseCrashlyticsLogStrategy(),
      DatadogLogStrategy(
        apiKey: 'your-datadog-api-key',
        service: 'my-app',
        env: 'production',
      ),
    ],
    enablePerformanceMonitoring: true,
  );

  // All logging methods are synchronous - no await needed!
  logger.info('App started successfully');
  logger.error('Something went wrong', stackTrace: StackTrace.current);
}
```

When initialized with a `projectName`, you'll see a beautiful colored banner with your app name in ASCII art. Without a `projectName`, it defaults to "STRATEGIC LOGGER".

---

## Features

### Logging Strategies
- **ConsoleLogStrategy** - Beautiful console output with ANSI color auto-detection
- **FirebaseAnalyticsLogStrategy** - Track events in Firebase Analytics
- **FirebaseCrashlyticsLogStrategy** - Report crashes and errors to Firebase Crashlytics
- **SentryLogStrategy** - Full Sentry integration for error tracking
- **DatadogLogStrategy** - APM and log management with HTTP batching
- **NewRelicLogStrategy** - Application monitoring with retry logic
- **Custom Strategies** - Extend `LogStrategy` for your own destinations

### Core Features
- **Auto-initialization** - Works out of the box with ConsoleLogStrategy
- **Synchronous API** - All logging methods return `void`, no `await` needed
- **Log Levels** - Debug, Info, Warning, Error, Fatal with intelligent routing
- **Structured Logging** - Rich metadata and context support
- **Event System** - Custom log events with parameters
- **Context Propagation** - Automatic context merging from entries and events
- **Strategy Filtering** - Filter logs by level and event type per strategy

### Performance Features
- **Isolate Processing** - Heavy operations run in background isolates
- **Performance Monitoring** - Built-in metrics and performance tracking
- **Async Queue** - Efficient log processing with backpressure control (1000 entry buffer)
- **Batch Processing** - Automatic batching for HTTP strategies (100 entries or 5s timeout)
- **Retry Logic** - Exponential backoff for failed network operations (3 retries max)

### Developer Experience
- **Modern Console** - Beautiful, colorful output with automatic terminal detection
- **Dynamic Banners** - Your project name displayed in ASCII art
- **Type Safety** - Full type safety in Dart with comprehensive documentation
- **Hot Reload** - Seamless development experience with Flutter
- **Platform Support** - Android, iOS, Linux, macOS, Web, Windows

---

## Strategy Configuration

### ConsoleLogStrategy - Beautiful Terminal Output

```dart
await logger.initialize(
  strategies: [
    ConsoleLogStrategy(
      logLevel: LogLevel.debug,
      useModernFormatting: true,  // Rich formatting with colors
      useColors: true,            // Enable ANSI colors
      autoDetectColors: true,     // Auto-detect terminal capabilities (iOS/Android safe)
      showTimestamp: true,        // Show timestamps
      showContext: true,          // Show context data
    ),
  ],
);
```

**Auto-detection ensures:**
- No ANSI garbage on iOS Simulator/Android Logcat
- Beautiful colors on macOS/Linux terminals
- Windows Terminal support (WT_SESSION, TERM, COLORTERM detection)

### Firebase Strategies - Analytics & Crashlytics

```dart
await logger.initialize(
  strategies: [
    FirebaseAnalyticsLogStrategy(
      logLevel: LogLevel.info,
    ),
    FirebaseCrashlyticsLogStrategy(
      logLevel: LogLevel.error,  // Only errors and fatals
    ),
  ],
);

// Logs automatically tracked in Firebase
logger.info('User logged in', context: {'userId': '123'});
logger.error('Payment failed', stackTrace: StackTrace.current);
```

### Sentry - Error Tracking

```dart
await logger.initialize(
  strategies: [
    SentryLogStrategy(
      logLevel: LogLevel.error,  // Only log errors to Sentry
    ),
  ],
);

// Errors sent to Sentry with full context
logger.error(
  'API request failed',
  context: {'endpoint': '/api/users', 'statusCode': 500},
  stackTrace: StackTrace.current,
);
```

### Datadog - APM & Log Management

```dart
await logger.initialize(
  strategies: [
    DatadogLogStrategy(
      apiKey: 'your-datadog-api-key',
      service: 'my-app',
      env: 'production',
      batchSize: 100,          // Batch 100 entries
      batchTimeout: Duration(seconds: 5),  // Or send after 5 seconds
      maxRetries: 3,           // Retry failed batches 3 times
    ),
  ],
);
```

**Features:**
- Automatic batching (100 entries or 5 seconds)
- Exponential backoff retry logic
- HTTP client with proper error handling

### New Relic - Application Monitoring

```dart
await logger.initialize(
  strategies: [
    NewRelicLogStrategy(
      licenseKey: 'your-newrelic-license',
      appName: 'my-app',
      batchSize: 50,
      batchTimeout: Duration(seconds: 10),
    ),
  ],
);
```

---

## Usage Examples

### Basic Logging

```dart
import 'package:strategic_logger/logger.dart';

void main() {
  // Works immediately - auto-initializes on first call!
  logger.debug('Debug message');
  logger.info('Info message');
  logger.warning('Warning message');
  logger.error('Error message');
  logger.fatal('Fatal error');
}
```

### Structured Logging with Context

```dart
// Rich context logging - context is passed to ALL strategies
logger.info('User action', context: {
  'userId': '123',
  'action': 'login',
  'timestamp': DateTime.now().toIso8601String(),
  'device': 'iPhone 15',
  'version': '1.2.3',
});

// Context is available in Datadog for indexing and filtering
// Context is added as Sentry extra fields
// Context is merged into Firebase Analytics parameters
// Context is displayed in console output

// Error with stack trace and context
try {
  throw Exception('Something went wrong');
} catch (e, stackTrace) {
  logger.error(
    'Operation failed',
    stackTrace: stackTrace,
    context: {
      'operation': 'data_sync',
      'retryCount': 3,
      'lastError': e.toString(),
    },
  );
}
```

### Multi-Strategy Logging

```dart
// Log to multiple destinations simultaneously
await logger.initialize(
  strategies: [
    ConsoleLogStrategy(useModernFormatting: true),
    SentryLogStrategy(),
    FirebaseCrashlyticsLogStrategy(),
    FirebaseAnalyticsLogStrategy(),
    DatadogLogStrategy(
      apiKey: 'your-datadog-api-key',
      service: 'my-app',
      env: 'production',
    ),
    NewRelicLogStrategy(
      licenseKey: 'your-newrelic-license',
      appName: 'my-app',
    ),
  ],
);

// One call, multiple destinations
logger.error('Critical system failure', context: {
  'component': 'payment_service',
  'severity': 'critical',
});
// This error will be logged to:
// - Console (with beautiful formatting)
// - Sentry (error tracking)
// - Firebase Crashlytics (crash reporting)
// - Firebase Analytics (event tracking)
// - Datadog (APM)
// - New Relic (monitoring)
```

### Real-time Log Streaming

```dart
// Listen to real-time log events
logger.logStream.listen((logEntry) {
  print('New log: ${logEntry.level} - ${logEntry.message}');

  // Update UI, send to external systems, etc.
  updateDashboard(logEntry);
});

// Logs will automatically appear in the stream
logger.info('User performed action');
```

### Flutter App Integration

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
    enablePerformanceMonitoring: true,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () {
              logger.info('Button pressed', context: {
                'screen': 'home',
                'timestamp': DateTime.now().toIso8601String(),
              });
            },
            child: const Text('Log Action'),
          ),
        ),
      ),
    );
  }
}
```

### Strategy-Specific Events

```dart
// Send a generic event to all strategies
logger.log(
  'purchase completed',
  event: LogEvent(
    eventName: 'PURCHASE_COMPLETED',
    parameters: {'amount': '99.99', 'currency': 'USD'},
  ),
);

// Send to a specific strategy using specialized events
logger.log(
  'purchase completed',
  event: FirebaseAnalyticsLogEvent(
    eventName: 'PURCHASE_COMPLETED',
    parameters: {'amount': '99.99'},
  ),
);

logger.error(
  'non-fatal error',
  event: FirebaseCrashlyticsLogEvent(
    eventName: 'ERROR',
    parameters: {'component': 'checkout'},
  ),
);
```

---

## Modern Console Output

Experience beautiful, structured console output:

```
14:30:25.123 DEBUG  User action completed
 Event: USER_ACTION
   Message: User completed purchase
   Parameters:
     userId: 123
     amount: 99.99
 Context:
   timestamp: 2024-01-15T14:30:25.123Z
   source: mobile_app
```

---

## Custom Strategies

Create custom strategies by extending `LogStrategy`:

```dart
import 'package:strategic_logger/logger.dart';
import 'package:strategic_logger/src/core/log_queue.dart';

class MyCustomLogStrategy extends LogStrategy {
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

    // Merge context from entry and event parameters
    final context = <String, dynamic>{};
    if (entry.context != null) context.addAll(entry.context!);
    if (entry.event?.parameters != null) {
      context.addAll(entry.event!.parameters!);
    }

    // Your implementation here
    await _sendToService({
      'message': entry.message.toString(),
      'level': entry.level.name,
      'timestamp': entry.timestamp.toIso8601String(),
      'context': context,
    });
  }
}
```

**The `LogEntry` object contains:**
- `message` - The log message
- `level` - The log level (debug, info, warning, error, fatal)
- `timestamp` - When the log was created
- `context` - Structured context map (`Map<String, dynamic>?`)
- `stackTrace` - Stack trace for errors (`StackTrace?`)
- `event` - Optional `LogEvent` object

---

## Performance

Strategic Logger is designed for high performance:

- **Isolate-based processing** prevents blocking the main thread
- **Automatic batching** reduces network overhead
- **Async queue with backpressure** handles high log volumes
- **Performance monitoring** tracks operation metrics
- **Synchronous fire-and-forget API** - logging calls return immediately

### Performance Metrics

```dart
final stats = logger.getPerformanceStats();
print('Total operations: ${stats['processLogEntry']?.totalOperations}');
print('Average duration: ${stats['processLogEntry']?.averageDuration}ms');
print('Error rate: ${stats['processLogEntry']?.errorRate}%');
```

---

## Migration Guide

### From v2.x to v3.0.0

v3.0.0 is a **major release** with breaking changes that simplify the API:

#### 1. Remove `await` from logging calls

```dart
// v2.x (old)
await logger.info('message');
await logger.error('error', stackTrace: StackTrace.current);

// v3.0.0 (new) - all logging methods are now void
logger.info('message');
logger.error('error', stackTrace: StackTrace.current);
```

> **Note**: In Dart, calling `await` on a `void` expression is a compilation error. You must remove `await` from all logging calls.

#### 2. Auto-initialization (optional)

```dart
// v2.x (old) - required initialization, crashed with NotInitializedError otherwise
await logger.initialize(strategies: [ConsoleLogStrategy()]);
logger.info('message');

// v3.0.0 (new) - works immediately, auto-initializes with ConsoleLogStrategy
logger.info('message');  // Just works!

// Explicit initialization is still recommended for production
await logger.initialize(strategies: [ConsoleLogStrategy(), SentryLogStrategy()]);
```

#### 3. Removed APIs

The following have been removed in v3.0.0:

| Removed | Replacement |
|---------|-------------|
| `logger.infoSync()` | `logger.info()` (already synchronous) |
| `logger.debugSync()` | `logger.debug()` |
| `logger.errorSync()` | `logger.error()` |
| `logger.warningSync()` | `logger.warning()` |
| `logger.fatalSync()` | `logger.fatal()` |
| `logger.verboseSync()` | `logger.verbose()` |
| `logger.logSync()` | `logger.log()` |
| `loggerCompatibility` | `logger` (use directly) |
| `NotInitializedError` | Auto-initialization (no longer thrown) |
| MCP module | Removed (scope creep) |
| AI module | Removed (scope creep) |

---

## Supported Platforms

- **Flutter** (iOS, Android, Web, Desktop)
- **Dart CLI** applications
- **Dart VM** applications
- **Flutter Web**
- **Flutter Desktop** (Windows, macOS, Linux)

---

## Contributing

We welcome contributions! Please see our [Code of Conduct](CODE_OF_CONDUCT.md) for community guidelines.

### Development Setup

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## Support

If you find Strategic Logger helpful, please consider:

- Starring the repository
- Reporting bugs
- Suggesting new features
- Contributing code

---

## Sponsored by

<div align="center">

**[Hypn Tech](https://hypn.com.br)** - *Maintainer & Sponsor*

*Building the future of mobile applications with cutting-edge technology*

</div>

---

## License

Strategic Logger is released under the **MIT License**. See [LICENSE](LICENSE) for details.

---

## Documentation & Resources

- [API Documentation](https://pub.dev/documentation/strategic_logger/latest/) - Complete API reference
- [Examples](example/) - Ready-to-use code examples
- [Changelog](CHANGELOG.md) - Version history and updates
- [Code of Conduct](CODE_OF_CONDUCT.md) - Community guidelines
- [GitHub Issues](https://github.com/Hypn-Tech/strategic_logger/issues) - Report bugs and request features
- [GitHub Repository](https://github.com/Hypn-Tech/strategic_logger) - Source code and contributions

---

<div align="center">

**Made with care by the Strategic Logger team**

[![GitHub](https://img.shields.io/badge/GitHub-100000?style=for-the-badge&logo=github&logoColor=white)](https://github.com/Hypn-Tech/strategic_logger)
[![Pub](https://img.shields.io/badge/Pub-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://pub.dev/packages/strategic_logger)

</div>
