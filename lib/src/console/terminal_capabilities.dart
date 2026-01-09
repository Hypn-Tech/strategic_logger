import 'dart:io' show Platform, stdout;

import 'package:flutter/foundation.dart' show kIsWeb;

/// Detects terminal capabilities for ANSI color support.
///
/// This class provides automatic detection of whether the current
/// environment supports ANSI escape codes for colored output.
///
/// **Usage:**
/// ```dart
/// if (TerminalCapabilities.supportsAnsiColors) {
///   print('\x1B[32mGreen text\x1B[0m');
/// } else {
///   print('Plain text');
/// }
/// ```
///
/// **Platform behavior:**
/// - iOS/Android: Returns `false` (Xcode/Logcat don't render ANSI)
/// - macOS/Linux terminal: Returns `true`
/// - Windows: Checks for modern terminal support
/// - Web: Returns `false`
class TerminalCapabilities {
  static bool? _supportsAnsi;

  /// Returns `true` if the current terminal supports ANSI escape codes.
  ///
  /// The result is cached after the first call for performance.
  static bool get supportsAnsiColors {
    if (_supportsAnsi != null) return _supportsAnsi!;
    _supportsAnsi = _detectAnsiSupport();
    return _supportsAnsi!;
  }

  static bool _detectAnsiSupport() {
    // Web never supports ANSI
    if (kIsWeb) return false;

    try {
      // iOS Simulator/Device: Flutter debug console doesn't support ANSI
      // The Xcode console displays escape codes as literal text
      if (Platform.isIOS) return false;

      // Android: Logcat doesn't render ANSI properly
      // Colors appear as garbage characters
      if (Platform.isAndroid) return false;

      // Check if stdout explicitly supports ANSI escapes
      // This works for real terminals on desktop
      if (stdout.supportsAnsiEscapes) return true;

      // macOS/Linux terminal: Usually supports ANSI
      if (Platform.isMacOS || Platform.isLinux) return true;

      // Windows: Check for modern terminal (Windows Terminal, ConEmu, etc.)
      if (Platform.isWindows) {
        final term = Platform.environment['TERM'];
        final colorTerm = Platform.environment['COLORTERM'];
        final wtSession = Platform.environment['WT_SESSION'];
        // Windows Terminal sets WT_SESSION
        // Other terminals may set TERM or COLORTERM
        return wtSession != null || term != null || colorTerm != null;
      }

      return false;
    } catch (_) {
      // If we can't detect (e.g., restricted environment), assume no support
      // This is the safer default to avoid garbage output
      return false;
    }
  }

  /// Force enable or disable ANSI color support.
  ///
  /// Use this for:
  /// - Testing purposes
  /// - User preference override
  /// - Forcing colors in CI/CD environments
  ///
  /// Pass `null` to reset to auto-detection.
  ///
  /// **Example:**
  /// ```dart
  /// // Force colors on
  /// TerminalCapabilities.setAnsiSupport(true);
  ///
  /// // Force colors off
  /// TerminalCapabilities.setAnsiSupport(false);
  ///
  /// // Reset to auto-detect
  /// TerminalCapabilities.setAnsiSupport(null);
  /// ```
  static void setAnsiSupport(bool? enabled) {
    _supportsAnsi = enabled;
  }

  /// Resets the cached detection result.
  ///
  /// Useful for testing or when environment conditions change.
  static void reset() {
    _supportsAnsi = null;
  }
}
