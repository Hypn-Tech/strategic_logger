import 'package:strategic_logger/logger.dart';

/// Example demonstrating context passing to strategies
/// 
/// This example shows how context data is now properly passed to all logging strategies,
/// enabling structured logging similar to Datadog and other modern logging platforms.
void main() async {
  print('🚀 Context Passing Example\n');
  
  // Initialize logger with console strategy
  await logger.initialize(
    strategies: [
      ConsoleLogStrategy(
        useModernFormatting: true,
        useColors: true,
        showTimestamp: true,
        showContext: true, // Enable context display
      ),
    ],
    level: LogLevel.debug,
    enablePerformanceMonitoring: false,
  );

  print('═══════════════════════════════════════════════════════');
  print('Example 1: User Action with Context');
  print('═══════════════════════════════════════════════════════\n');
  
  // Log user action with rich context
  await logger.info(
    'User logged in successfully',
    context: {
      'userId': 'user_12345',
      'email': 'john.doe@example.com',
      'ipAddress': '192.168.1.100',
      'userAgent': 'Mozilla/5.0',
      'sessionId': 'session_abc123',
      'loginMethod': 'oauth2',
    },
  );

  await Future.delayed(Duration(milliseconds: 100));

  print('\n═══════════════════════════════════════════════════════');
  print('Example 2: API Request with Context');
  print('═══════════════════════════════════════════════════════\n');
  
  // Log API request with context
  await logger.info(
    'API request processed',
    context: {
      'requestId': 'req_789xyz',
      'method': 'POST',
      'endpoint': '/api/v1/users',
      'statusCode': 200,
      'responseTime': '45ms',
      'userId': 'user_12345',
    },
  );

  await Future.delayed(Duration(milliseconds: 100));

  print('\n═══════════════════════════════════════════════════════');
  print('Example 3: Error with Context');
  print('═══════════════════════════════════════════════════════\n');
  
  // Log error with rich debugging context
  await logger.error(
    'Failed to process payment',
    context: {
      'paymentId': 'pay_98765',
      'userId': 'user_12345',
      'amount': 99.99,
      'currency': 'USD',
      'errorCode': 'INSUFFICIENT_FUNDS',
      'retryAttempt': 3,
      'merchantId': 'merchant_xyz',
      'timestamp': DateTime.now().toIso8601String(),
    },
    stackTrace: StackTrace.current,
  );

  await Future.delayed(Duration(milliseconds: 100));

  print('\n═══════════════════════════════════════════════════════');
  print('Example 4: Performance Metric with Context');
  print('═══════════════════════════════════════════════════════\n');
  
  // Log performance metric with context
  await logger.info(
    'Database query completed',
    context: {
      'queryType': 'SELECT',
      'table': 'users',
      'duration': '123ms',
      'rowsReturned': 150,
      'cacheHit': false,
      'indexUsed': true,
      'connectionPoolSize': 10,
    },
  );

  await Future.delayed(Duration(milliseconds: 100));

  print('\n═══════════════════════════════════════════════════════');
  print('Example 5: Business Event with Context and Event');
  print('═══════════════════════════════════════════════════════\n');
  
  // Log business event with both context and event parameters
  await logger.info(
    'Purchase completed',
    event: LogEvent(
      eventName: 'PURCHASE_COMPLETED',
      eventMessage: 'Customer completed checkout',
      parameters: {
        'orderId': 'order_456',
        'totalAmount': 299.99,
      },
    ),
    context: {
      'userId': 'user_12345',
      'sessionId': 'session_abc123',
      'cartSize': 3,
      'discountApplied': true,
      'discountCode': 'SUMMER2024',
      'paymentMethod': 'credit_card',
      'shippingMethod': 'express',
    },
  );

  await Future.delayed(Duration(milliseconds: 100));

  print('\n═══════════════════════════════════════════════════════');
  print('Example 6: Distributed Tracing with Context');
  print('═══════════════════════════════════════════════════════\n');
  
  // Log with distributed tracing context
  await logger.debug(
    'Service call initiated',
    context: {
      'traceId': 'trace_123abc456def',
      'spanId': 'span_789xyz',
      'parentSpanId': 'span_456uvw',
      'service': 'user-service',
      'operation': 'getUserProfile',
      'correlationId': 'corr_321zyx',
    },
  );

  await Future.delayed(Duration(milliseconds: 100));

  print('\n═══════════════════════════════════════════════════════');
  print('✅ Examples Complete');
  print('═══════════════════════════════════════════════════════\n');

  print('📝 Key Benefits:\n');
  print('1. Structured Data: Context is now properly sent to all strategies');
  print('2. Rich Debugging: All relevant information is captured');
  print('3. Correlation: Trace requests across services with IDs');
  print('4. Analytics: Extract insights from structured context data');
  print('5. Monitoring: Track performance metrics with context');
  
  // Clean up
  logger.dispose();
}
