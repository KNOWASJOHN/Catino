import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

final Logger _logger = Logger('cantino');

/// Initialize logging. Call this early in `main()` if you want console
/// debug prints while developing.
void initLogging({Level level = Level.INFO}) {
  Logger.root.level = level;
  Logger.root.onRecord.listen((record) {
    final message = '[${record.level.name}] ${record.time.toIso8601String()} ${record.loggerName}: ${record.message}';
    // In debug builds, also print to console for easier debugging
    if (kDebugMode) {
      // Use debugPrint so output is throttled appropriately
      debugPrint(message);
      if (record.error != null) debugPrint('Error: ${record.error}');
      if (record.stackTrace != null) debugPrint('StackTrace: ${record.stackTrace}');
    }
    // TODO: forward logs to an external logging/monitoring service in release
  });
}

void logDebug(String message) => _logger.fine(message);
void logInfo(String message) => _logger.info(message);
void logWarning(String message) => _logger.warning(message);
void logError(String message, [Object? error, StackTrace? stackTrace]) => _logger.severe(message, error, stackTrace);
