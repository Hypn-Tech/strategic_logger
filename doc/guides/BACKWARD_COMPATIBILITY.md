# ✅ Backward Compatibility - v1.4.0

## Zero Breaking Changes!

Version 1.4.0 is **fully backward compatible**. Your existing custom strategies continue to work without any modifications, and they now automatically receive context!

## How It Works

The `LogStrategy` class now has **default implementations** that delegate to legacy methods:

1. **New methods** (`log(LogEntry)`, `info(LogEntry)`, etc.) have default implementations
2. **Default implementations** call legacy methods (`logMessage()`, `logError()`) with context
3. **Legacy strategies** continue to work and now receive context automatically
4. **New strategies** can override the new methods for better type safety

## Legacy Strategies (No Changes Needed!)

If you have a strategy written for v1.3.0 or earlier, it continues to work:

```dart
class MyLegacyStrategy extends LogStrategy {
  @override
  Future<void> logMessage(
    dynamic message,
    LogEvent? event,
    Map<String, dynamic>? context,  // ← Context is now available!
  ) async {
    // Your existing code works without changes
    print('Message: $message');
    if (context != null) {
      print('Context: $context');  // ← This now works!
    }
  }
  
  @override
  Future<void> logError(
    dynamic error,
    StackTrace? stackTrace,
    LogEvent? event,
    Map<String, dynamic>? context,  // ← Context is now available!
  ) async {
    // Your existing code works without changes
    print('Error: $error');
    if (context != null) {
      print('Context: $context');  // ← This now works!
    }
  }
}
```

**No code changes required!** Your strategy now automatically receives context when you call:

```dart
await logger.log("message", context: {"userId": 123});
```

## New Strategies (Recommended)

For new code, use the new interface for better type safety:

```dart
import 'package:strategic_logger/src/core/log_queue.dart';

class MyNewStrategy extends LogStrategy {
  @override
  Future<void> log(LogEntry entry) async {
    // Access all information from LogEntry
    final message = entry.message;
    final level = entry.level;
    final timestamp = entry.timestamp;
    final context = entry.context;  // Full context available
    final event = entry.event;
    
    // Your implementation
  }
  
  @override
  Future<void> info(LogEntry entry) async {
    await log(entry);
  }
  
  @override
  Future<void> error(LogEntry entry) async {
    final error = entry.message;
    final stackTrace = entry.stackTrace;
    final context = entry.context;  // Full context available
    
    // Your implementation
  }
  
  @override
  Future<void> fatal(LogEntry entry) async {
    await error(entry);
  }
}
```

## Benefits

1. ✅ **Zero Breaking Changes**: Old strategies work without modification
2. ✅ **Context Works Everywhere**: Even legacy strategies receive context automatically
3. ✅ **Gradual Migration**: Migrate to new interface when convenient
4. ✅ **Better Type Safety**: New interface provides better type safety with LogEntry

## Migration (Optional)

You can migrate your legacy strategies to the new interface when convenient:

**Before (Legacy):**
```dart
@override
Future<void> logMessage(dynamic message, LogEvent? event, Map<String, dynamic>? context) async {
  // Implementation
}
```

**After (New):**
```dart
@override
Future<void> log(LogEntry entry) async {
  // Access: entry.message, entry.context, entry.event, etc.
  // Implementation
}
```

**But this is optional!** Legacy strategies continue to work perfectly.

## Summary

- ✅ **No breaking changes** - all existing code works
- ✅ **Context works everywhere** - even in legacy strategies
- ✅ **Optional migration** - migrate when convenient
- ✅ **Better type safety** - new interface recommended for new code
