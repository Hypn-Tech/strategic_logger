import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

// Platform detection
import 'package:flutter/foundation.dart' show kIsWeb;

import '../core/log_queue.dart';
import '../events/log_event.dart';
import '../enums/log_level.dart';
import '../strategies/log_strategy.dart';
import 'mcp_server.dart';

/// MCP Log Strategy for Strategic Logger
///
/// ⚠️ **SECURITY WARNING**: This strategy starts an HTTP server that exposes logs.
/// **NOT recommended for production mobile/web apps** without proper authentication.
///
/// This strategy integrates with the Model Context Protocol (MCP) server
/// to provide AI agents with structured logging capabilities.
///
/// **Security Considerations:**
/// - HTTP server exposes logs without authentication by default
/// - Should only be used in development or with proper security measures
/// - Not recommended for Flutter mobile apps in production
/// - Consider using only in local development environments
///
/// Features:
/// - Structured logging for AI consumption
/// - Real-time log streaming
/// - Query capabilities for log analysis
/// - Health monitoring through logs
///
/// Example (Development only):
/// ```dart
/// // Only use in development!
/// MCPLogStrategy(
///   enableInMobile: false, // Disabled by default for security
///   apiKey: 'your-secret-key', // Required for production
/// )
/// ```
class MCPLogStrategy extends LogStrategy {
  final MCPServer _mcpServer;
  final bool _enableRealTimeStreaming;
  final bool _enableHealthMonitoring;
  final Map<String, dynamic> _defaultContext;
  final bool _enableInMobile;
  final String? _apiKey;

  /// Constructs an [MCPLogStrategy].
  ///
  /// ⚠️ **SECURITY WARNING**: This strategy starts an HTTP server.
  /// - [enableInMobile] - Set to true to enable in mobile (default: false for security)
  /// - [apiKey] - Optional API key for authentication (recommended for production)
  /// - [mcpServer] - Custom MCP server instance
  /// - [enableRealTimeStreaming] - Enable real-time log streaming
  /// - [enableHealthMonitoring] - Enable health monitoring
  /// - [defaultContext] - Default context to add to all logs
  MCPLogStrategy({
    MCPServer? mcpServer,
    bool enableInMobile = false,
    String? apiKey,
    bool enableRealTimeStreaming = true,
    bool enableHealthMonitoring = true,
    Map<String, dynamic>? defaultContext,
  }) : _mcpServer = mcpServer ?? MCPServer.instance,
       _enableInMobile = enableInMobile,
       _apiKey = apiKey,
       _enableRealTimeStreaming = enableRealTimeStreaming,
       _enableHealthMonitoring = enableHealthMonitoring,
       _defaultContext = defaultContext ?? {} {
    // Security check: Warn if trying to use in mobile/web without explicit enable
    if (!_enableInMobile && (kIsWeb || Platform.isAndroid || Platform.isIOS)) {
      developer.log(
        '⚠️ MCP Server is disabled by default in mobile/web for security. '
        'Set enableInMobile: true only if you understand the risks. '
        'MCP Server exposes logs via HTTP without authentication by default.',
        name: 'MCPLogStrategy',
      );
      // Don't throw error, just log warning - strategy will work but server won't start
    }

    logLevel = LogLevel.info;
    loggerLogLevel = LogLevel.info;
    supportedEvents = [
      LogEvent(eventName: 'mcp_log', eventMessage: 'MCP structured log entry'),
    ];
  }

  /// Starts the MCP server if not already running
  ///
  /// ⚠️ **Security**: Server will only start if enabled for mobile/web platforms.
  Future<void> startServer() async {
    // Security check: Don't start server in mobile/web unless explicitly enabled
    if (!_enableInMobile && (kIsWeb || Platform.isAndroid || Platform.isIOS)) {
      developer.log(
        '⚠️ MCP Server start blocked: Not enabled for mobile/web. '
        'Set enableInMobile: true to allow (security risk!).',
        name: 'MCPLogStrategy',
      );
      return;
    }

    if (!_mcpServer.isRunning) {
      await _mcpServer.start(apiKey: _apiKey);
    }
  }

  /// Stops the MCP server
  Future<void> stopServer() async {
    if (_mcpServer.isRunning) {
      await _mcpServer.stop();
    }
  }

  @override
  Future<void> log(LogEntry entry) async {
    await _logToMCP(entry);
  }

  @override
  Future<void> info(LogEntry entry) async {
    await _logToMCP(entry);
  }

  @override
  Future<void> error(LogEntry entry) async {
    await _logToMCP(entry);
  }

  @override
  Future<void> fatal(LogEntry entry) async {
    await _logToMCP(entry);
  }

  /// Logs a message to the MCP server
  Future<void> _logToMCP(LogEntry entry) async {
    try {
      // Ensure server is running
      if (!_mcpServer.isRunning) {
        await startServer();
      }

      // Merge context from entry.context and event.parameters
      final mergedContext = <String, dynamic>{};
      if (entry.context != null) {
        mergedContext.addAll(entry.context!);
      }
      if (entry.event?.parameters != null) {
        mergedContext.addAll(entry.event!.parameters!);
      }
      if (entry.stackTrace != null) {
        mergedContext['stackTrace'] = entry.stackTrace.toString();
      }

      // Create structured log entry
      final mcpLogEntry = MCPLogEntry(
        id: _generateLogId(),
        timestamp: entry.timestamp,
        level: entry.level,
        message: _formatMessage(entry.message),
        context: mergedContext.isNotEmpty ? mergedContext : <String, dynamic>{},
        event: entry.event,
        source: 'strategic_logger_mcp',
      );

      // Add to MCP server
      _mcpServer.addLogEntry(mcpLogEntry);

      // Enable real-time streaming if configured
      if (_enableRealTimeStreaming) {
        await _streamLogEntry(mcpLogEntry);
      }

      // Health monitoring
      if (_enableHealthMonitoring) {
        await _updateHealthMetrics(mcpLogEntry);
      }
    } catch (e) {
      // Fallback to developer log if MCP fails
      developer.log(
        'Failed to log to MCP: $e',
        name: 'MCPLogStrategy',
        error: e,
      );
    }
  }

  /// Generates a unique log ID
  String _generateLogId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${Uri.encodeComponent('mcp_log')}';
  }

  /// Formats a message for logging
  String _formatMessage(dynamic message) {
    if (message == null) return 'null';
    if (message is String) return message;
    if (message is Map || message is List) {
      return jsonEncode(message);
    }
    return message.toString();
  }

  /// Builds context for the log entry
  Map<String, dynamic> _buildContext(
    Map<String, dynamic>? additionalContext,
    StackTrace? stackTrace,
  ) {
    final context = Map<String, dynamic>.from(_defaultContext);

    if (additionalContext != null) {
      context.addAll(additionalContext);
    }

    if (stackTrace != null) {
      context['stackTrace'] = stackTrace.toString();
    }

    // Add MCP-specific context
    context['mcp_timestamp'] = DateTime.now().toIso8601String();
    context['mcp_source'] = 'strategic_logger';
    context['mcp_version'] = '1.1.0';

    return context;
  }

  /// Streams a log entry for real-time monitoring
  Future<void> _streamLogEntry(MCPLogEntry entry) async {
    try {
      // In a real implementation, this would send to a streaming endpoint
      // For now, we'll just log to developer console
      developer.log(
        'MCP Stream: ${entry.level.name} - ${entry.message}',
        name: 'MCPLogStrategy',
      );
    } catch (e) {
      developer.log(
        'Failed to stream log entry: $e',
        name: 'MCPLogStrategy',
        error: e,
      );
    }
  }

  /// Updates health metrics based on log entry
  Future<void> _updateHealthMetrics(MCPLogEntry entry) async {
    try {
      // Update health metrics based on log level
      switch (entry.level) {
        case LogLevel.error:
        case LogLevel.fatal:
          // Increment error count
          _incrementErrorCount();
          break;
        case LogLevel.warning:
          // Increment warning count
          _incrementWarningCount();
          break;
        default:
          // Increment info count
          _incrementInfoCount();
          break;
      }
    } catch (e) {
      developer.log(
        'Failed to update health metrics: $e',
        name: 'MCPLogStrategy',
        error: e,
      );
    }
  }

  /// Increments error count for health monitoring
  void _incrementErrorCount() {
    // In a real implementation, this would update health metrics
    developer.log('Health: Error count incremented', name: 'MCPLogStrategy');
  }

  /// Increments warning count for health monitoring
  void _incrementWarningCount() {
    // In a real implementation, this would update health metrics
    developer.log('Health: Warning count incremented', name: 'MCPLogStrategy');
  }

  /// Increments info count for health monitoring
  void _incrementInfoCount() {
    // In a real implementation, this would update health metrics
    developer.log('Health: Info count incremented', name: 'MCPLogStrategy');
  }

  /// Queries logs from the MCP server
  Future<List<MCPLogEntry>> queryLogs({
    LogLevel? level,
    DateTime? since,
    DateTime? until,
    String? message,
    Map<String, String>? context,
    String? sortBy,
    int? limit,
  }) async {
    try {
      // In a real implementation, this would query the MCP server
      // For now, we'll return an empty list
      return [];
    } catch (e) {
      developer.log(
        'Failed to query logs: $e',
        name: 'MCPLogStrategy',
        error: e,
      );
      return [];
    }
  }

  /// Gets health status from the MCP server
  Future<Map<String, dynamic>> getHealthStatus() async {
    try {
      // In a real implementation, this would query the MCP server health endpoint
      return {
        'status': 'healthy',
        'mcp_server': _mcpServer.isRunning,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'status': 'unhealthy',
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// MCP Server instance for testing
  MCPServer get mcpServer => _mcpServer;

  /// Generate log ID for testing
  String generateLogId() => _generateLogId();

  /// Format message for testing
  String formatMessage(dynamic message) => _formatMessage(message);

  /// Build context for testing
  Map<String, dynamic> buildContext(
    Map<String, dynamic>? additionalContext,
    StackTrace? stackTrace,
  ) => _buildContext(additionalContext, stackTrace);

  @override
  String toString() {
    return 'MCPLogStrategy(server: ${_mcpServer.isRunning}, streaming: $_enableRealTimeStreaming, health: $_enableHealthMonitoring)';
  }

  void dispose() {
    // Clean up resources
    stopServer();
  }
}
