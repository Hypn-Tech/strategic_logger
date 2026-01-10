# Strategic Logger

```
  ___  _____  ___    _  _____  ___  ___  ___  ___
 / __||_   _|| _ \  /_\|_   _|| __|| __||_ _|/ __|
 \__ \  | |  |   / / _ \ | |  | _| | |_  | || (__
 |___/  |_|  |_|_\/_/ \_\|_|  |___||___||___|\___|

  / /    / __ \ / ____| / ____|/ ____|| _ \
 / /    | |  | | |  __ | |  __| |__   |   /
/ /___ | |__| | |_| | | |_| ||  __| | |\ \
/_____| \____/ \____| |\_____|\____||_| \_\

              Powered by Hypn Tech
                 hypn.com.br
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

## 🏢 Sponsored by Hypn Tech

[![Hypn Tech](https://hypn.com.br/wp-content/uploads/2024/05/marca-hypn-institucional-1536x738.png)](https://hypn.com.br)

**Strategic Logger is proudly sponsored and maintained by [Hypn Tech](https://hypn.com.br)**

*Desenvolva seu app com a Hypn Tech - Soluções completas em desenvolvimento mobile e web*

</div>

---

## ✨ Why Strategic Logger?

### 🎯 **One Call, All Strategies**
Log once and send to multiple destinations simultaneously - Console, Firebase, Sentry, Datadog, New Relic.

### ⚡ **Performance First**
- **Isolate-based processing** - Never block the main thread
- **Async queue with backpressure** - Handle high log volumes efficiently
- **Batch processing** - Automatic batching for network strategies
- **Smart retry logic** - Exponential backoff for failed operations

### 🎨 **Beautiful Console Output**
- **Auto-detect terminal capabilities** - iOS/Android safe, no ANSI garbage
- **Modern formatting** with colors and structured layout
- **Rich context display** with metadata and stack traces
- **Timestamp precision** with millisecond accuracy
- **Dynamic project banners** - Your app name in ASCII art

### 🔌 **Enterprise-Ready Integrations**
- **Firebase Analytics & Crashlytics** - Complete Firebase suite support
- **Sentry** - Full error tracking integration
- **Datadog** - APM and log management
- **New Relic** - Application monitoring
- **Custom strategies** - Extend with your own logging destinations

### 🔄 **Drop-in Replacement**
100% compatible with popular logger packages - no code changes required!

---

## 🚀 Quick Start

### Installation

Add Strategic Logger to your `pubspec.yaml`:

```yaml
dependencies:
  strategic_logger: ^2.0.0
```

Then run:
```bash
flutter pub get
```

### Basic Usage

```dart
import 'package:strategic_logger/logger.dart';

void main() async {
  // Initialize once at app startup
  await logger.initialize(
    projectName: 'My App',  // Your project name appears in the banner!
    level: LogLevel.debug,
    strategies: [
      ConsoleLogStrategy(
        useModernFormatting: true,
        useColors: true,
      ),
      // Traditional strategies
      FirebaseAnalyticsLogStrategy(),
      FirebaseCrashlyticsLogStrategy(),
    ],
    useIsolates: true,
    enablePerformanceMonitoring: true,
  );

  // Start logging!
  await logger.info('App started successfully');
  await logger.error('Something went wrong', stackTrace: StackTrace.current);
}
```

When initialized, you'll see a beautiful colored banner with your project name:

```
           __ ___ ___
|\/|\_/   |__|__]|__]
|  | |    |  ||   |

  Strategic Logger powered by Hypn Tech (hypn.com.br)
```

If you don't provide a `projectName`, it defaults to showing "STRATEGIC LOGGER":

```
 __ ______  __ ______  __ ___  __        __  __  __ ___ ___
[__  | |__/|__| | |__ | _  |  |    |   |  || _ | _ |__ |__/
___] | |  \|  | | |___|__]_|_ |__  |___|__||__]|__]|___|  \

  Strategic Logger powered by Hypn Tech (hypn.com.br)
```

---

## 🎯 Features

### 🔌 **Logging Strategies**
- **ConsoleLogStrategy** - Beautiful console output with ANSI color auto-detection
- **FirebaseAnalyticsLogStrategy** - Track events in Firebase Analytics
- **FirebaseCrashlyticsLogStrategy** - Report crashes and errors to Firebase Crashlytics
- **SentryLogStrategy** - Full Sentry integration for error tracking
- **DatadogLogStrategy** - APM and log management with HTTP batching
- **NewRelicLogStrategy** - Application monitoring with retry logic
- **Custom Strategies** - Extend `LogStrategy` for your own destinations

### 🔧 **Core Features**
- **Log Levels** - Debug, Info, Warning, Error, Fatal with intelligent routing
- **Structured Logging** - Rich metadata and context support
- **Event System** - Custom log events with parameters
- **Context Propagation** - Automatic context merging from entries and events
- **Error Handling** - Robust error management with predefined types
- **Strategy Filtering** - Filter logs by level and event type per strategy

### 🚀 **Performance Features**
- **Isolate Processing** - Heavy operations run in background isolates
- **Performance Monitoring** - Built-in metrics and performance tracking
- **Async Queue** - Efficient log processing with backpressure control (1000 entry buffer)
- **Batch Processing** - Automatic batching for HTTP strategies (100 entries or 5s timeout)
- **Retry Logic** - Exponential backoff for failed network operations (3 retries max)

### 🎨 **Developer Experience**
- **Modern Console** - Beautiful, colorful output with automatic terminal detection
- **Dynamic Banners** - Your project name displayed in ASCII art
- **Compatibility Layer** - Drop-in replacement for popular logger packages
- **Type Safety** - Full type safety in Dart with comprehensive documentation
- **Hot Reload** - Seamless development experience with Flutter
- **Platform Support** - Android, iOS, Linux, macOS, Web, Windows

---

## 📊 Strategy Configuration

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
- ✅ No ANSI garbage (`\^[[36m`) on iOS Simulator/Android Logcat
- ✅ Beautiful colors on macOS/Linux terminals
- ✅ Windows Terminal support (WT_SESSION, TERM, COLORTERM detection)

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
await logger.info('User logged in', context: {'userId': '123'});
await logger.error('Payment failed', stackTrace: StackTrace.current);
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
await logger.error(
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

## 📖 Usage Examples

### 🚀 Basic Logging

```dart
import 'package:strategic_logger/logger.dart';

// Initialize logger
await logger.initialize(
  strategies: [
    ConsoleLogStrategy(
      useModernFormatting: true,
      useColors: true,
          ),
  ],
  enablePerformanceMonitoring: true,
);

// Basic logging
await logger.debug('Debug message');
await logger.info('Info message');
await logger.warning('Warning message');
await logger.error('Error message');
await logger.fatal('Fatal error');
```

### 🎯 Structured Logging with Context

```dart
// Rich context logging - context is now passed to ALL strategies
await logger.info('User action', context: {
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
  // Some risky operation
  throw Exception('Something went wrong');
} catch (e, stackTrace) {
  await logger.error(
    'Operation failed',
    stackTrace: stackTrace,
    context: {
      'operation': 'data_sync',
      'retryCount': 3,
      'lastError': e.toString(),
    },
  );
}

// Datadog will receive context fields directly in the log entry
// You can filter and search by these fields in Datadog
```

### 🔥 Multi-Strategy Logging

```dart
// Log to multiple destinations simultaneously
await logger.initialize(
  strategies: [
    ConsoleLogStrategy(useModernFormatting: true),
    SentryLogStrategy(dsn: 'your-sentry-dsn'),
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
await logger.error('Critical system failure', context: {
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

### 🔄 Real-time Log Streaming

```dart
// Listen to real-time log events
logger.logStream.listen((logEntry) {
  print('New log: ${logEntry.level} - ${logEntry.message}');
  
  // Update UI, send to external systems, etc.
  updateDashboard(logEntry);
});

// Logs will automatically appear in the stream
await logger.info('User performed action');
```

### 📱 Flutter App Integration

```dart
class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _initializeLogger();
  }

  Future<void> _initializeLogger() async {
    await logger.initialize(
      strategies: [
        ConsoleLogStrategy(useModernFormatting: true),
        FirebaseCrashlyticsLogStrategy(),
      ],
      enablePerformanceMonitoring: true,
    );
    
    logger.info('App initialized successfully');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () async {
              await logger.info('Button pressed', context: {
                'screen': 'home',
                'timestamp': DateTime.now().toIso8601String(),
              });
            },
            child: Text('Log Action'),
          ),
        ),
      ),
    );
  }
}
```

### 🔧 Advanced Configuration

```dart
// Custom configuration with all features
await logger.initialize(
  strategies: [
    ConsoleLogStrategy(
      useModernFormatting: true,
      useColors: true,
            showTimestamp: true,
      showContext: true,
    ),
    SentryLogStrategy(
      dsn: 'your-sentry-dsn',
      environment: 'production',
    ),
    DatadogLogStrategy(
      apiKey: 'your-datadog-api-key',
      site: 'datadoghq.com',
      service: 'my-flutter-app',
    ),
  ],
  level: LogLevel.info,
  useIsolates: true, // Enable isolate-based processing
  enablePerformanceMonitoring: true,
  enableModernConsole: true,
);

// Performance monitoring
final stats = logger.getPerformanceStats();
print('Logs processed: ${stats['totalLogs']}');
print('Average processing time: ${stats['avgProcessingTime']}ms');

// Force flush all queued logs
await logger.flush();
```

### 🔄 Drop-in Replacement (Compatibility)

```dart
// 100% compatible with popular logger packages
logger.debugSync('Debug message');
logger.infoSync('Info message');
logger.errorSync('Error message');

// Or use the compatibility extension
loggerCompatibility.debug('Debug message');
loggerCompatibility.info('Info message');
loggerCompatibility.error('Error message');
```

---

## 🎨 Modern Console Output

Experience beautiful, structured console output:

```
🐛 14:30:25.123 DEBUG  User action completed
📋 Event: USER_ACTION
   Message: User completed purchase
   Parameters:
     userId: 123
     amount: 99.99
🔍 Context:
   timestamp: 2024-01-15T14:30:25.123Z
   source: mobile_app
```

---

## 🔧 Configuration

### Advanced Initialization

```dart
await logger.initialize(
  level: LogLevel.info,
  strategies: [
    // Console with modern formatting
    ConsoleLogStrategy(
      useModernFormatting: true,
      useColors: true,
            showTimestamp: true,
      showContext: true,
    ),
    
    // Firebase Analytics
    FirebaseAnalyticsLogStrategy(),
    
    // Firebase Crashlytics
    FirebaseCrashlyticsLogStrategy(),
    
    // Datadog (v2 API with compression)
    DatadogLogStrategy(
      apiKey: 'your-datadog-api-key',
      service: 'my-app',
      env: 'production',
      tags: 'team:mobile,version:1.0.0',
      enableCompression: true, // Default: true, reduces network overhead
      // Uses v2 endpoint: https://http-intake.logs.datadoghq.com/api/v2/logs
    ),
    
    // New Relic
    NewRelicLogStrategy(
      licenseKey: 'your-newrelic-license-key',
      appName: 'my-app',
      environment: 'production',
    ),
  ],
  
  // Modern features
  useIsolates: true,
  enablePerformanceMonitoring: true,
  enableModernConsole: true,
);
```

### Custom Strategies

You can create custom strategies in two ways:

#### Option 1: New Way (Recommended for new code)

```dart
import 'package:strategic_logger/src/core/log_queue.dart';

class MyCustomLogStrategy extends LogStrategy {
  @override
  Future<void> log(LogEntry entry) async {
    // Access all log information from the entry
    final message = entry.message;
    final level = entry.level;
    final timestamp = entry.timestamp;
    final context = entry.context; // Context is available!
    final event = entry.event;
    
    // Your implementation
    await _sendToCustomService({
      'message': message.toString(),
      'level': level.name,
      'timestamp': timestamp.toIso8601String(),
      'context': context,
      'event': event?.toMap(),
    });
  }
  
  @override
  Future<void> info(LogEntry entry) async {
    await log(entry);
  }
  
  @override
  Future<void> error(LogEntry entry) async {
    // Access error information including stackTrace and context
    final error = entry.message;
    final stackTrace = entry.stackTrace;
    final context = entry.context; // Context is available!
    
    await log(entry);
  }
  
  @override
  Future<void> fatal(LogEntry entry) async {
    await error(entry);
  }
}
```

#### Option 2: Legacy Way (Still works! No changes needed!)

```dart
class MyLegacyStrategy extends LogStrategy {
  @override
  Future<void> logMessage(
    dynamic message,
    LogEvent? event,
    Map<String, dynamic>? context,  // Context is now available automatically! 🎉
  ) async {
    // Your old implementation - still works!
    print('Message: $message');
    if (context != null) {
      print('Context: $context');  // Context works without any changes!
    }
  }
  
  @override
  Future<void> logError(
    dynamic error,
    StackTrace? stackTrace,
    LogEvent? event,
    Map<String, dynamic>? context,  // Context is now available automatically! 🎉
  ) async {
    // Your old implementation - still works!
    print('Error: $error');
    if (context != null) {
      print('Context: $context');  // Context works without any changes!
    }
  }
}
```

**Note**: The `LogEntry` object contains:
- `message` - The log message
- `level` - The log level (debug, info, warning, error, fatal)
- `timestamp` - When the log was created
- `context` - Structured context map (Map<String, dynamic>?)
- `stackTrace` - Stack trace for errors (StackTrace?)
- `event` - Optional LogEvent object

---

## 📊 Performance

Strategic Logger is designed for high performance:

- **Isolate-based processing** prevents blocking the main thread
- **Automatic batching** reduces network overhead
- **Async queue with backpressure** handles high log volumes
- **Performance monitoring** tracks operation metrics
- **Efficient serialization** minimizes memory usage

### Performance Metrics

```dart
final stats = logger.getPerformanceStats();
print('Total operations: ${stats['processLogEntry']?.totalOperations}');
print('Average duration: ${stats['processLogEntry']?.averageDuration}ms');
print('Error rate: ${stats['processLogEntry']?.errorRate}%');
```

---

## ✅ Backward Compatible - No Breaking Changes!

**✅ Zero Breaking Changes**: Old custom strategies continue to work without modification!
**✅ Context Now Available**: Even legacy strategies automatically receive context.
**✅ All built-in strategies updated**: Using new interface for better context support.
**✅ Public API unchanged**: `logger.log()`, `logger.info()`, etc. work the same way.

**Legacy strategies** can continue using `logMessage()` and `logError()` - they now receive context automatically!
**New strategies** should use `log(LogEntry)`, `info(LogEntry)`, etc. for better type safety.

## 🆕 Migration Guide

### From v0.1.x to v0.2.x

The new version introduces breaking changes for better performance and modern features:

```dart
// Old way (v0.1.x)
logger.initialize(
  level: LogLevel.info,
  strategies: [ConsoleLogStrategy()],
);

// New way (v0.2.x)
await logger.initialize(
  level: LogLevel.info,
  strategies: [
    ConsoleLogStrategy(
      useModernFormatting: true,
      useColors: true,
          ),
  ],
  useIsolates: true,
  enablePerformanceMonitoring: true,
  enableModernConsole: true,
);
```

---

## 🌐 Supported Platforms

- ✅ **Flutter** (iOS, Android, Web, Desktop)
- ✅ **Dart CLI** applications
- ✅ **Dart VM** applications
- ✅ **Flutter Web**
- ✅ **Flutter Desktop** (Windows, macOS, Linux)

---

## 🎯 Use Cases & Applications

### 🏢 **Enterprise Applications**
- **Microservices Architecture** - Centralized logging across distributed systems
- **High-Traffic Applications** - Handle millions of logs with isolate-based processing
- **Real-time Monitoring** - Multi-strategy logging to Datadog, New Relic, Sentry
- **Compliance & Auditing** - Structured logging for regulatory requirements

### 📱 **Mobile & Flutter Applications**
- **Cross-Platform Logging** - Consistent logging across iOS, Android, Web, Desktop
- **Performance Optimization** - Isolate-based processing for smooth UI
- **Crash Analytics** - Integration with Firebase Crashlytics and Sentry
- **User Behavior Tracking** - Structured logging for analytics

### ☁️ **Cloud & DevOps**
- **Multi-Cloud Support** - Datadog, New Relic, AWS CloudWatch integration
- **Container Logging** - Optimized for Docker and Kubernetes environments
- **Serverless Functions** - Efficient logging for Lambda and Cloud Functions
- **CI/CD Integration** - Automated testing and deployment logging

---

## 🗺️ Roadmap

### ✅ **v2.0.0 - Simplification Release (Released)**
- [x] **Code Cleanup** - Removed unused ObjectPool and LogCompression
- [x] **Dynamic Banner** - Project name displayed in colored ASCII art
- [x] **Context Propagation** - `mergedContext` getter for unified context access
- [x] **Simplified API** - Cleaner strategy interface

### 🔧 **v2.1.0 - Developer Experience (Q2 2025)**
- [ ] **HTTP Strategy Base Class** - Extract common patterns from Datadog/NewRelic
- [ ] **Better Error Messages** - Improved initialization error handling
- [ ] **Performance Improvements** - Reduce isolate overhead for simple operations

### 🚀 **v3.0.0 - Cloud Native & Ecosystem (Q3 2025)**
- [ ] **Grafana Integration** - Custom dashboards and intelligent alerts
- [ ] **Prometheus Integration** - Detailed metrics and Kubernetes integration
- [ ] **Developer Tools** - VS Code extension and CLI tools
- [ ] **OpenTelemetry** - Distributed tracing support

---

## 🤝 Contributing

We welcome contributions! Please see our [Code of Conduct](CODE_OF_CONDUCT.md) for community guidelines.

### Development Setup

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 💖 Support

If you find Strategic Logger helpful, please consider:

- ⭐ **Starring** the repository
- 🐛 **Reporting** bugs
- 💡 **Suggesting** new features
- 🤝 **Contributing** code
- ☕ [Buy me a coffee](https://www.buymeacoffee.com/sauloroncon)

---

## 🏢 Sponsored by

<div align="center">

**[Hypn Tech](https://hypn.com.br)** - *Maintainer & Sponsor*

*Building the future of mobile applications with cutting-edge technology*

</div>

---

## 📄 License

Strategic Logger is released under the **MIT License**. See [LICENSE](LICENSE) for details.

---

## 📚 Documentation & Resources

### 📖 **Official Documentation**
- [API Documentation](https://pub.dev/documentation/strategic_logger/latest/) - Complete API reference
- [Examples](example/) - Ready-to-use code examples
- [Changelog](CHANGELOG.md) - Version history and updates
- [Code of Conduct](CODE_OF_CONDUCT.md) - Community guidelines

### 🎓 **Learning Resources**
- [API Documentation](https://pub.dev/documentation/strategic_logger/latest/) - Complete API reference
- [Examples](example/) - Ready-to-use code examples
- [Changelog](CHANGELOG.md) - Version history and updates
- [Contributing Guide](CODE_OF_CONDUCT.md) - Code of conduct

### 🌟 **Community**
- [GitHub Issues](https://github.com/Hypn-Tech/strategic_logger/issues) - Report bugs and request features
- [GitHub Repository](https://github.com/Hypn-Tech/strategic_logger) - Source code and contributions

---

<div align="center">

**Made with ❤️ by the Strategic Logger team**

[![GitHub](https://img.shields.io/badge/GitHub-100000?style=for-the-badge&logo=github&logoColor=white)](https://github.com/Hypn-Tech/strategic_logger)
[![Pub](https://img.shields.io/badge/Pub-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://pub.dev/packages/strategic_logger)

---


</div>