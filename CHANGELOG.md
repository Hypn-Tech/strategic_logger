# 2.0.1

## 🎨 Dynamic Banner & Documentation Update - Strategic Logger 2.0.1

### ✨ New Features
- **Dynamic Project Banner** - Your project name displayed in colored ASCII art at initialization!
  ```dart
  await logger.initialize(
    projectName: 'MY APP',  // Shows "MY APP" in gradient ASCII art
    strategies: [ConsoleLogStrategy()],
  );
  ```

### 🎨 Visual Improvements
- **Modern ASCII Banner** - Gradient colors (cyan → blue → magenta) like Claude Code CLI
- **No more box borders** - Clean, modern look without `███` borders
- **Dynamic text generation** - ASCII art generated from any project name
- **Default banner** - Shows "STRATEGIC LOGGER" if no projectName provided

### 📚 Documentation
- Updated README.md with v2.0.0 changes and new banner examples
- Updated example/example.dart with projectName usage
- Fixed deprecated `useEmojis` parameter references in documentation
- Updated roadmap to reflect v2.0.0 release

---

# 2.0.0

## 🚀 Simplification Release - Strategic Logger 2.0.0

> **Clean Architecture & Clean Code**: Removed ~1,900 lines of unused code following CLAUDE.md guidelines.

### ⚠️ Breaking Changes
- **Removed** `ObjectPool` class - was never integrated into the logger, zero impact
- **Removed** `LogCompression` class - was never integrated into the logger, zero impact

### ✨ New Features
- **`LogEntry.mergedContext` getter** - Unified method to merge `entry.context` with `entry.event.parameters`
- **CLAUDE.md** - Comprehensive development guidelines for contributors

### 🔧 Improvements
- All strategies now use `entry.mergedContext` for consistent context handling
- Eliminated code duplication across 6 strategy implementations
- Reduced codebase by ~1,900 lines of dead code
- Better code organization following Clean Architecture principles

### 📊 Code Quality
- Removed unused `ObjectPool` (452 lines)
- Removed unused `LogCompression` (508 lines)
- Removed associated test files (~960 lines)
- Simplified context merging pattern in all strategies

### 🔄 Migration Notes
- If you were importing `ObjectPool` or `LogCompression`, remove those imports (they were never functional)
- All other code works without changes

---

# 1.4.2

## 🔧 Bug Fixes - Strategic Logger 1.4.2

### Fixed
- Removed version display from console initialization banner to prevent version mismatch issues

---

# 1.4.1

## 🔧 Bug Fixes - Strategic Logger 1.4.1

### Fixed
- Removed hardcoded version from console initialization banner
- Removed `_getPackageVersion()` method that was causing version mismatch (was showing 1.2.2 instead of published version)
- Removed unused `dart:io` import

### Changed
- Version display removed from ASCII art banner to avoid version synchronization issues when package is used as dependency

---

# 1.4.0

## 🚀 Major Improvements - Strategic Logger 1.4.0

> **✅ NO BREAKING CHANGES**: Backward compatible! Old custom strategies continue to work and now receive context automatically.
> **✅ All built-in strategies updated**: Using new LogEntry interface for better context support.
> **✅ Public API unchanged**: `logger.log()`, `logger.info()`, etc. work the same way.

### ✨ New Features
- **Full Context Support**: Context is now properly passed to all strategies
- **Datadog v2 API**: Updated to use the official v2 endpoint with proper JSON format
- **Gzip Compression**: Added optional gzip compression for Datadog logs (enabled by default)
- **LogEntry-based Strategy Interface**: Strategies now receive complete LogEntry objects with full context

### 🔧 Datadog Strategy Improvements
- **v2 Endpoint**: Changed default URL from `https://http-intake.logs.datadoghq.com/v1/input` to `https://http-intake.logs.datadoghq.com/api/v2/logs`
- **Gzip Compression**: Added `enableCompression` parameter (default: true) to reduce network overhead
- **Proper v2 Format**: Logs now use Datadog v2 JSON format with `ddsource`, `ddtags`, `hostname`, `message`, `service`, `status`, `timestamp` fields
- **Context Integration**: Context fields are now properly added to Datadog log entries for indexing and filtering

### 📊 Context Propagation
- **Full Context Support**: When calling `logger.log("message", context: {"user_id": 123})`, the context is now passed to all strategies
- **Merged Context**: Context from both `entry.context` and `event.parameters` is merged and available to strategies
- **Structured Fields**: Context fields are added directly to log entries in backends like Datadog for better indexing

### 🔄 API Changes (Backward Compatible!)
- **Strategy Interface**: Strategies can now receive `LogEntry` objects with full context
  - New way: Override `log(LogEntry entry)`, `info(LogEntry entry)`, `error(LogEntry entry)`, `fatal(LogEntry entry)`
  - Legacy way: Override `logMessage()` and `logError()` - **still works and now receives context automatically!**
- **Default Implementations**: Methods have default implementations that delegate to legacy methods
- **Zero Breaking Changes**: Old custom strategies continue to work without modification
- **Context Now Available**: Even legacy strategies receive context automatically via `logMessage()` and `logError()`

### 🎯 Updated Strategies
- **ConsoleLogStrategy**: Now displays context information in formatted output
- **DatadogLogStrategy**: Updated to v2 API with compression and proper context handling
- **SentryLogStrategy**: Context is now added as Sentry extra fields
- **FirebaseAnalyticsLogStrategy**: Context is merged into event parameters
- **FirebaseCrashlyticsLogStrategy**: Context is added as custom keys
- **NewRelicLogStrategy**: Context is included in log attributes
- **MCPLogStrategy**: Context is merged into MCP log entries
- **AILogStrategy**: Context is included in AI analysis

### 🐛 Bug Fixes
- **Context Not Passed**: Fixed issue where context was never passed to strategies
- **Datadog Old Endpoint**: Updated to use current v2 endpoint
- **Missing Compression**: Added gzip compression for network efficiency

### 🔒 Security Improvements
- **MCP Server Security**: Added authentication support and disabled by default in mobile/web
- **Security Warnings**: Added clear warnings about MCP and AI strategy risks
- **Mobile Protection**: MCP Server blocked by default in Flutter mobile apps
- **Authentication**: Optional API key authentication for MCP Server
- **Documentation**: Created SECURITY_ANALYSIS.md with detailed security assessment

### 📚 Documentation
- Updated README with Datadog v2 setup instructions
- Added examples showing structured context usage
- Updated CHANGELOG with comprehensive change list
- Created BACKWARD_COMPATIBILITY.md explaining how legacy strategies work
- Created example/legacy_strategy_example.dart demonstrating backward compatibility
- Created SECURITY_ANALYSIS.md with security recommendations
- Added security warnings for MCP and AI strategies


### 📦 Dependencies
- No new dependencies added
- All existing dependencies remain compatible

---

# 1.3.0

## 🏢 Repository Transfer & Ownership Update - Strategic Logger 1.3.0

### 🏢 Repository Transfer
- **New Ownership**: Repository transferred from `sauloroncon` to `Hypn-Tech` organization
- **Updated URLs**: All repository URLs updated to reflect new ownership
- **Maintained Continuity**: All existing functionality and features preserved
- **Enhanced Support**: Now officially maintained by Hypn Tech team

### 🔧 Configuration Updates
- **Repository URLs**: Updated all references to point to `https://github.com/Hypn-Tech/strategic_logger`
- **Issue Tracker**: Updated to new repository issue tracker
- **Documentation**: Updated documentation links to new repository
- **Package Metadata**: Updated pubspec.yaml with new repository information

### 📦 Package Updates
- **Version Bump**: Incremented to version 1.3.0 to reflect repository transfer
- **Metadata Cleanup**: Updated package metadata for new ownership
- **Documentation Sync**: Synchronized all documentation with new repository structure

### 🏢 Hypn Tech Integration
- **Official Sponsorship**: Strategic Logger is now officially sponsored and maintained by Hypn Tech
- **Enhanced Support**: Professional support and maintenance from Hypn Tech team
- **Enterprise Ready**: Enhanced enterprise support and commercial backing
- **Long-term Commitment**: Long-term maintenance and development commitment

### 🔄 Migration Notes
- **No Breaking Changes**: All existing code continues to work without modifications
- **URL Updates**: Update any hardcoded repository URLs in your projects
- **Documentation**: Refer to new repository for latest documentation and examples
- **Support**: Contact Hypn Tech for professional support and enterprise features

---

# 1.2.3

## 🎨 Enhanced ASCII Art with Solid Characters - Strategic Logger 1.2.3

### ✨ New Features
- **Solid ASCII Art**: Replaced double-line characters (═) with solid block characters (█) for better visibility
- **Enhanced Log Highlighting**: ASCII art now uses solid rectangles for better contrast and readability
- **Improved Visual Impact**: More prominent and eye-catching ASCII art display

### 🎨 UI/UX Improvements
- **Better Contrast**: Solid characters provide better visual separation from regular logs
- **Enhanced Readability**: ASCII art stands out more prominently in console output
- **Professional Appearance**: Solid block characters give a more modern, technical look
- **Consistent Branding**: Updated both package and README.md ASCII art for consistency

### 🔧 Technical Improvements
- **Character Optimization**: Using Unicode block characters (█) for maximum visibility
- **Cross-Platform Compatibility**: Solid characters display consistently across all platforms
- **Visual Hierarchy**: Better distinction between ASCII art and regular log messages
- **Brand Consistency**: Unified ASCII art style across all documentation

### 📱 ASCII Art Features
- **Solid Borders**: All borders now use solid block characters (█)
- **Enhanced Visibility**: Better contrast against terminal backgrounds
- **Modern Design**: Clean, technical appearance with solid character blocks
- **Consistent Styling**: Unified appearance across package and documentation

---

# 1.2.4

## 🔧 Static Analysis Fixes & Code Quality - Strategic Logger 1.2.4

### 🐛 Bug Fixes
- **Static Analysis Score**: Achieved maximum pub.dev static analysis score (50/50)
- **Code Quality**: Resolved all critical lint issues and warnings
- **Unused Variables**: Removed unused fields and local variables
- **Library Directives**: Added proper library directives to fix documentation warnings

### 🔧 Technical Improvements
- **Code Cleanup**: Removed unnecessary cast operations
- **Field Optimization**: Eliminated unused `_useEmojis` field from ConsoleLogStrategy
- **Variable Cleanup**: Removed unused local variables (`dim`, `levelColor`) from formatting methods
- **Documentation**: Fixed dangling library doc comments with proper library directives

### 📊 Quality Metrics
- **Before**: 8 static analysis issues
- **After**: 0 critical issues (only minor `avoid_print` warnings in examples)
- **Score**: 50/50 points (100%)
- **Compliance**: Full pub.dev quality standards compliance

### 🎯 Code Quality Features
- **Clean Code**: Eliminated all unnecessary code and variables
- **Proper Documentation**: Fixed library documentation structure
- **Type Safety**: Improved type safety with proper casting
- **Maintainability**: Enhanced code maintainability and readability

---

# 1.2.3

## 🎨 Visual Improvements & Log Formatting - Strategic Logger 1.2.3

### ✨ New Features
- **Visual Log Headers**: Beautiful colored headers with `[HYPN-TECH][STRATEGIC-LOGGER][LEVEL]` format
- **Enhanced ASCII Art**: Improved alignment of "Powered by Hypn Tech" text
- **Clean Log Format**: Removed duplicate level indicators for cleaner output
- **Professional Branding**: Consistent Hypn Tech branding throughout all logs

### 🎨 Visual Improvements
- **Colored Headers**: Each log level has distinct colors (INFO=green, WARNING=yellow, ERROR=red, FATAL=bright red, DEBUG=magenta)
- **Brand Integration**: HYPN-TECH and STRATEGIC-LOGGER prominently displayed with brand colors
- **Clean Output**: Eliminated redundant level indicators for professional appearance
- **ASCII Art Alignment**: Perfect alignment of branding text in ASCII art

### 🔧 Technical Improvements
- **Log Level Handling**: Fixed warning logs to display as WARN instead of INFO
- **Emoji Removal**: Removed all emojis from package and example for professional appearance
- **Color Management**: Enhanced ANSI color codes for better terminal compatibility
- **Format Consistency**: Standardized log format across all strategies

### 📱 Console Features
- **Visual Hierarchy**: Clear visual separation between brand, package, and log level
- **Color Coding**: Intuitive color scheme for different log levels
- **Professional Appearance**: Clean, corporate-friendly log formatting
- **Terminal Compatibility**: Optimized for various terminal environments

### 🏢 Branding Updates
- **Consistent Branding**: Hypn Tech branding integrated throughout logging system
- **Professional Look**: Corporate-friendly appearance suitable for enterprise use
- **Visual Identity**: Strong visual identity with branded headers
- **Clean Design**: Minimalist approach focusing on readability and professionalism

---

# 1.2.2

## 🎨 ASCII Art & Version Display Improvements - Strategic Logger 1.2.2

### ✨ New Features
- **Dynamic Version Display**: ASCII art now displays version dynamically from pubspec.yaml
- **Enhanced ASCII Art**: Improved positioning and formatting of version information
- **Clean Configuration Logs**: Replaced complex box with simple `[HYPN-TECH]` header format

### 🎨 UI/UX Improvements
- **Version Integration**: Version now appears elegantly in the ASCII art banner
- **Simplified Log Format**: Configuration logs use clean `[HYPN-TECH]` prefix format
- **Professional Branding**: Enhanced Hypn Tech branding integration
- **Dynamic Version Reading**: Automatic version detection from pubspec.yaml

### 🔧 Technical Improvements
- **Version Detection**: Added `_getPackageVersion()` method to read version from pubspec.yaml
- **Fallback Handling**: Robust fallback to default version if pubspec.yaml cannot be read
- **Code Organization**: Improved ASCII art generation with dynamic version integration
- **Maintainability**: Version updates automatically reflect in ASCII art

### 📱 ASCII Art Features
- **Dynamic Version**: `v1.2.2` automatically displayed in ASCII art
- **Professional Layout**: Clean, modern ASCII art with proper spacing
- **Brand Integration**: Hypn Tech branding prominently displayed
- **Version Positioning**: Elegant version placement within ASCII art structure

---

# 1.2.1

## 🔧 Static Analysis Improvements - Strategic Logger 1.2.1

### 🐛 Bug Fixes
- **Static Analysis Score**: Improved pub.dev static analysis score from 40/50 to 50/50
- **Code Formatting**: Fixed all Dart formatting issues across the codebase
- **Library Names**: Removed unnecessary library name declarations
- **String Interpolations**: Fixed unnecessary string interpolations and braces
- **Field Overrides**: Corrected field override issues in AI and MCP strategies

### 🔧 Technical Improvements
- **Code Quality**: Achieved maximum pub.dev static analysis score
- **Dart Format**: All files now properly formatted with `dart format`
- **Lint Compliance**: Resolved all critical lint issues
- **Performance**: Maintained all existing functionality while improving code quality

### 📊 Static Analysis Results
- **Before**: 40/50 points (80%)
- **After**: 50/50 points (100%)
- **Issues Fixed**: 29 critical issues resolved
- **Remaining**: Only minor `avoid_print` warnings in example files (acceptable)

---

# 1.2.0

## 🎨 UI/UX Improvements & Bug Fixes - Strategic Logger 1.2.0

### ✨ New Features
- **Enhanced Example App**: Complete redesign with Hypn Tech branding and modern UI
- **Real-time Console**: Live console integration with auto-scroll functionality
- **Mobile-First Design**: Optimized button layout with 4 buttons per line
- **Interactive Strategy Management**: Real-time strategy configuration with switches
- **Clickable Branding**: Hypn Tech logo and website link integration

### 🎨 UI/UX Improvements
- **Modern Design**: Hypn Tech inspired visual design with vibrant teal color scheme
- **Compact Stats Panel**: Always-visible statistics panel with dynamic counters
- **Fixed Console**: Collapsible console at bottom with minimize/expand functionality
- **Responsive Layout**: Mobile-first approach with optimized touch targets
- **Professional Branding**: Hypn Tech logo integration and proper attribution

### 🐛 Bug Fixes
- **Terminal Log Visibility**: Fixed logs not appearing in Flutter terminal output
- **ASCII Art Display**: Corrected ASCII art generation and display in console
- **Strategy Configuration**: Fixed automatic strategy configuration application
- **Lint Error Resolution**: Resolved all static analysis issues for pub.dev compliance
- **Example App Stability**: Fixed corrupted example app and restored functionality

### 🔧 Technical Improvements
- **Console Output**: Added `print()` calls for terminal visibility alongside DevTools logging
- **ASCII Art Generation**: Improved ASCII art generation with figlet tool integration
- **Strategy Management**: Streamlined strategy configuration with automatic application
- **Error Handling**: Enhanced error handling in example app and core package
- **Code Quality**: Achieved maximum pub.dev score with lint error resolution

### 📱 Example App Features
- **Live Console**: Real-time log display with automatic scrolling
- **Strategy Switches**: Interactive strategy enable/disable with immediate effect
- **Performance Stats**: Real-time performance metrics display
- **Brand Integration**: Hypn Tech logo and website link
- **Mobile Optimization**: Touch-friendly interface with proper spacing

### 🏢 Branding Updates
- **Hypn Tech Integration**: Complete branding integration throughout example app
- **Professional Appearance**: Modern, clean design matching Hypn Tech aesthetic
- **Clickable Links**: Direct integration with Hypn Tech website
- **Consistent Theming**: Teal color scheme matching brand identity

---

# 1.1.3

## 🚀 Platform Detection & Web Compatibility - Strategic Logger 1.1.2

### ✨ New Features
- **Automatic Platform Detection**: Package now automatically detects platform capabilities
- **Web Compatibility**: Isolates are automatically disabled on web platform
- **Cross-Platform Support**: Seamless operation across web, mobile, and desktop platforms
- **Smart Defaults**: `useIsolates` parameter is now optional with intelligent defaults

### 🔧 Technical Improvements
- **Platform Detection Method**: Added `_isIsolateSupported()` for runtime platform detection
- **Web Platform Handling**: Uses `kIsWeb` to detect web platform and disable isolates
- **Backward Compatibility**: Maintains support for explicit `useIsolates` parameter
- **Error Prevention**: Prevents isolate-related errors on unsupported platforms

### 📱 Platform Support
- **Web**: Isolates automatically disabled, console logging optimized
- **Mobile (iOS/Android)**: Full isolate support for performance
- **Desktop (macOS/Windows/Linux)**: Full isolate support for performance

---

# 1.1.1

## 🐛 Bug Fixes - Strategic Logger 1.1.1

### 🐛 Bug Fixes
- **Integration Test Fixes**: Fixed `LateInitializationError` type recognition in integration tests
- **Test Stability**: Improved test reliability and error handling
- **Error Assertion Updates**: Updated error assertions to use string-based checks for better compatibility

### 🧪 Testing Improvements
- **Integration Test Reliability**: Enhanced integration test stability and error handling
- **Test Coverage**: Maintained test coverage above 80% with improved test quality
- **Error Handling Tests**: Better error handling validation in test scenarios

---

# 1.1.0

## 🚀 Major Release - Strategic Logger 1.1.0

### ✨ New Features
- **MCP (Model Context Protocol) Integration**: Native MCP server for AI agent integration
- **AI-Powered Log Analysis**: Intelligent log analysis with pattern detection and insights
- **Object Pool Management**: Efficient memory management with object pooling
- **Log Compression**: Network and storage optimization with intelligent compression
- **Advanced Performance Testing**: Comprehensive performance test suite
- **Integration Testing**: End-to-end integration tests for all components
- **Enhanced Test Coverage**: Test coverage exceeding 80% for all new features
- **Worker Pool Management**: Advanced isolate management with worker pools
- **Priority Queue System**: Intelligent log processing with priority-based queuing
- **Network Optimizations**: Compression, batching, circuit breakers, and retry mechanisms
- **Lazy Loading Support**: On-demand loading of strategies and components
- **Advanced Error Recovery**: Enhanced error handling with exponential backoff

### 🔧 Enhanced Features
- **Performance Monitoring**: Extended metrics and monitoring capabilities
- **Isolate Management**: Improved isolate pool management and fallback mechanisms
- **Memory Management**: Enhanced memory optimization and cleanup operations
- **Console Formatting**: Additional formatting options and customization
- **Error Handling**: More robust error handling and recovery mechanisms
- **Documentation**: Updated documentation with new features and examples

### 🧪 Testing Improvements
- **Performance Tests**: Comprehensive performance testing suite
- **Integration Tests**: End-to-end integration testing
- **Unit Tests**: Enhanced unit test coverage for all components
- **Stress Tests**: Stress testing for high-volume scenarios
- **Regression Tests**: Performance regression testing
- **Memory Tests**: Memory usage and leak testing

### 📚 Documentation Updates
- **New Features**: Documentation for MCP, AI, Object Pool, and Compression features
- **Examples**: Updated examples with new functionality
- **Performance Guide**: Performance optimization guidelines
- **Testing Guide**: Testing best practices and examples
- **Integration Guide**: Integration patterns and examples

---

# 1.0.0

## 🚀 Major Release - Strategic Logger 1.0.0

### ✨ New Features
- **Multi-threading with Isolates**: Offload heavy logging tasks to background isolates for improved performance
- **Modern Console Formatting**: Beautiful console output with colors, emojis, timestamps, and structured formatting
- **Performance Monitoring**: Built-in metrics tracking for logging operations
- **Asynchronous Log Queue**: Efficient log processing with backpressure control
- **New Logging Strategies**: 
  - Datadog integration
  - New Relic integration
- **Enhanced Compatibility**: Seamless replacement of existing logger packages without code changes

### 🔧 Technical Improvements
- **Isolate Manager**: Manages a pool of isolates for parallel processing
- **Log Queue System**: Asynchronous queue with backpressure for high-volume logging
- **Performance Monitor**: Tracks processing times, queue sizes, and isolate usage
- **Modern Console Formatter**: Advanced ANSI escape codes for beautiful output
- **Synchronous Compatibility Layer**: Extension methods for backward compatibility

### 📚 Documentation
- **Complete README Redesign**: Modern, attractive documentation inspired by popular pub.dev packages
- **Comprehensive Examples**: Updated examples showcasing all new features
- **Migration Guide**: Step-by-step guide for upgrading from previous versions

### 🏢 Sponsorship
- **Hypn Tech**: Proudly sponsored and maintained by [Hypn Tech](https://hypn.com.br)

### 🔄 Breaking Changes
- None - fully backward compatible with previous versions

### 📦 Dependencies
- Updated to latest compatible versions
- Added new dependencies for modern features (ansicolor, collection, meta, json_annotation)

---

# 0.2.0

Updating sdk and dependencies versions

# 0.1.12

Updating dependencies versions 
# 0.1.11

Updating dependencies versions 
# 0.1.10

README improvments
# 0.1.9

Firebase Analytics & Crashlytics just log your own events
# 0.1.8

Firebase Analytics & Crashlytics export correction

# 0.1.7

Crashlytics import correction

# 0.1.6

Sentry Strategy dartdoc updated

# 0.1.5

Sentry Strategy created

# 0.1.4

Dart Format

# 0.1.3

Example Adjustments

# 0.1.2

Platforms Adjustments

# 0.1.1

Platforms Adjustments

# 0.1.0

Initial Version of the strategic logger.
