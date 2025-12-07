import 'package:logging/logging.dart';

/// Centralized logger for the application.
///
/// Provides a wrapper around the logging package with predefined
/// log levels and formatting. Use this instead of print() statements.
class AppLogger {
  // Private constructor to prevent instantiation
  AppLogger._();

  static final Logger _logger = Logger('ReadWhere');
  static bool _initialized = false;

  /// Initializes the logger with the specified log level.
  ///
  /// [level] defaults to Level.INFO for production.
  /// Call this once at app startup before using any logging methods.
  static void initialize({Level level = Level.INFO}) {
    if (_initialized) return;

    Logger.root.level = level;
    Logger.root.onRecord.listen((record) {
      // Format: [LEVEL] Time - Logger: Message
      final time = record.time.toString().split('.').first;
      print('[${record.level.name}] $time - ${record.loggerName}: ${record.message}');

      if (record.error != null) {
        print('Error: ${record.error}');
      }

      if (record.stackTrace != null) {
        print('Stack trace:\n${record.stackTrace}');
      }
    });

    _initialized = true;
    _logger.info('Logger initialized with level: ${level.name}');
  }

  /// Logs a debug message.
  ///
  /// Use for detailed debugging information that's useful during development.
  /// These messages are typically not shown in production.
  static void debug(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.fine(message, error, stackTrace);
  }

  /// Logs an info message.
  ///
  /// Use for general informational messages about app state and flow.
  static void info(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.info(message, error, stackTrace);
  }

  /// Logs a warning message.
  ///
  /// Use for potentially harmful situations that don't prevent
  /// the app from functioning but should be addressed.
  static void warning(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.warning(message, error, stackTrace);
  }

  /// Logs an error message.
  ///
  /// Use for error events that might still allow the app to continue running.
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.severe(message, error, stackTrace);
  }

  /// Logs a critical error message.
  ///
  /// Use for very severe error events that might cause the app to abort.
  static void critical(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.shout(message, error, stackTrace);
  }

  /// Logs method entry with optional parameters.
  ///
  /// Useful for tracing method calls during debugging.
  static void enterMethod(String methodName, [Map<String, dynamic>? params]) {
    if (params != null && params.isNotEmpty) {
      _logger.finest('→ Entering $methodName with params: $params');
    } else {
      _logger.finest('→ Entering $methodName');
    }
  }

  /// Logs method exit with optional return value.
  ///
  /// Useful for tracing method calls during debugging.
  static void exitMethod(String methodName, [dynamic returnValue]) {
    if (returnValue != null) {
      _logger.finest('← Exiting $methodName with result: $returnValue');
    } else {
      _logger.finest('← Exiting $methodName');
    }
  }
}
