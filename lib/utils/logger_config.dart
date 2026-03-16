import 'package:logging/logging.dart';

/// Centralized logger configuration for the application.
/// 
/// Usage:
/// ```dart
/// final logger = AppLogger.getLogger('MyClass');
/// logger.info('Information message');
/// logger.warning('Warning message');
/// logger.severe('Error message');
/// ```
class AppLogger {
  static bool _initialized = false;

  /// Initialize the logger configuration.
  /// Should be called once at app startup.
  static void initialize({Level level = Level.INFO}) {
    if (_initialized) return;
    
    Logger.root.level = level;
    Logger.root.onRecord.listen((record) {
      // Format: [LEVEL] LoggerName: Message
      final emoji = _getEmojiForLevel(record.level);
        // ...removed print statement...
      
      // Print error and stack trace if present
      if (record.error != null) {
          // ...removed print statement...
      }
      if (record.stackTrace != null) {
          // ...removed print statement...
      }
    });
    
    _initialized = true;
  }

  /// Get a logger instance for the given name.
  /// Typically use the class name as the logger name.
  static Logger getLogger(String name) {
    return Logger(name);
  }

  /// Get emoji based on log level for better visual distinction
  static String _getEmojiForLevel(Level level) {
    if (level == Level.SEVERE || level == Level.SHOUT) {
      return '❌';
    } else if (level == Level.WARNING) {
      return '⚠️';
    } else if (level == Level.INFO) {
      return 'ℹ️';
    } else if (level == Level.CONFIG) {
      return '⚙️';
    } else if (level == Level.FINE || level == Level.FINER || level == Level.FINEST) {
      return '🔍';
    }
    return '📝';
  }
}
