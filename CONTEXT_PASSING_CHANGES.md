# Context Passing to Strategies - Change Summary

## Issue
The context parameter was not being passed from the logger to the strategies, making it impossible for strategies like Datadog to access structured logging context data.

## Changes Made

### 1. Updated LogStrategy Abstract Class
Added `context` parameter to all abstract methods:
- `log()` - now accepts `Map<String, dynamic>? context`
- `info()` - now accepts `Map<String, dynamic>? context`
- `error()` - now accepts `Map<String, dynamic>? context`
- `fatal()` - now accepts `Map<String, dynamic>? context`

### 2. Updated StrategicLogger
Modified `_executeStrategy()` method to pass `entry.context` to all strategy method calls.

### 3. Updated All Strategy Implementations
Updated all strategies to accept and use the context parameter:
- ConsoleLogStrategy - merges context with event parameters for display
- DatadogLogStrategy - includes context in log entries sent to Datadog
- SentryLogStrategy - adds context to Sentry scope
- NewRelicLogStrategy - merges context into attributes
- FirebaseCrashlyticsLogStrategy - sets context as custom keys
- FirebaseAnalyticsLogStrategy - merges context with event parameters
- MCPLogStrategy - merges context into log entry context
- AILogStrategy - merges context into AI log entry context

## Usage Example

Before this fix, context was ignored:
```dart
await logger.info(
  'User logged in',
  context: {'userId': '123', 'action': 'login'}, // This was ignored!
);
```

After this fix, context is properly passed to all strategies:
```dart
await logger.info(
  'User logged in',
  context: {'userId': '123', 'action': 'login'}, // Now properly sent to strategies!
);

// The context will be:
// - Displayed in console logs
// - Sent to Datadog as additional fields
// - Added to Sentry scope
// - Included in Firebase Crashlytics custom keys
// - Merged with Firebase Analytics event parameters
// - Available in MCP logs for AI analysis
```

## Testing

Created comprehensive test suite in `test/context_passing_test.dart` that verifies:
- Context is passed to all log levels (debug, info, warning, error, fatal)
- Context works with events
- Empty and null context don't cause errors
- Context is properly captured by strategies

## Backward Compatibility

This change is backward compatible:
- The context parameter is optional (nullable)
- Existing code without context will continue to work
- Strategies handle null/empty context gracefully

## Impact

This fix enables:
1. **Structured Logging**: Full support for Datadog-style structured logging
2. **Better Debugging**: Rich context data available in all monitoring tools
3. **Enhanced Observability**: Trace requests through systems with correlation IDs
4. **Improved Error Tracking**: Error context automatically captured and sent to error tracking services
