import 'dart:io';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

enum LogLevel { debug, info, warning, error, fatal }

class LoggingService {
  static final List<String> _logs = [];
  static const int _maxLogs = 1000;
  static File? _logFile;

  static Future<void> initialize() async {
    if (!kReleaseMode) {
      try {
        final directory = await getApplicationDocumentsDirectory();
        _logFile = File('${directory.path}/app_logs.txt');
        await _logFile?.writeAsString('');
      } catch (e) {
        developer.log('Failed to initialize logging: $e');
      }
    }
  }

  static void log(String message, {LogLevel level = LogLevel.info, String? tag}) {
    final timestamp = DateTime.now();
    final formattedTime = DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(timestamp);
    final logEntry = '[$formattedTime] [${level.name.toUpperCase()}] ${tag ?? 'APP'}: $message';

    _logs.add(logEntry);
    if (_logs.length > _maxLogs) {
      _logs.removeAt(0);
    }

    if (!kReleaseMode) {
      developer.log(logEntry);
      _writeToFile(logEntry);
    }

    if (level == LogLevel.error || level == LogLevel.fatal) {
      _writeToFile(logEntry);
    }
  }

  static void debug(String message, {String? tag}) {
    log(message, level: LogLevel.debug, tag: tag);
  }

  static void info(String message, {String? tag}) {
    log(message, level: LogLevel.info, tag: tag);
  }

  static void warning(String message, {String? tag}) {
    log(message, level: LogLevel.warning, tag: tag);
  }

  static void error(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    final fullMessage = error != null ? '$message: $error' : message;
    log(fullMessage, level: LogLevel.error, tag: tag);
    
    if (stackTrace != null && !kReleaseMode) {
      developer.log('Stack trace: $stackTrace');
    }
  }

  static void fatal(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    final fullMessage = error != null ? '$message: $error' : message;
    log(fullMessage, level: LogLevel.fatal, tag: tag);
    
    if (stackTrace != null && !kReleaseMode) {
      developer.log('Stack trace: $stackTrace');
    }
  }

  static Future<void> _writeToFile(String logEntry) async {
    try {
      await _logFile?.writeAsString('$logEntry\n', mode: FileMode.append);
    } catch (e) {
      developer.log('Failed to write to log file: $e');
    }
  }

  static List<String> getLogs({LogLevel? minLevel, String? tag}) {
    var filteredLogs = _logs;

    if (minLevel != null) {
      final minIndex = LogLevel.values.indexOf(minLevel);
      filteredLogs = filteredLogs.where((log) {
        final levelStr = log.split(']')[1].trim();
        final level = LogLevel.values.firstWhere(
          (l) => l.name.toUpperCase() == levelStr.substring(1),
          orElse: () => LogLevel.info,
        );
        return LogLevel.values.indexOf(level) >= minIndex;
      }).toList();
    }

    if (tag != null) {
      filteredLogs = filteredLogs.where((log) => log.contains('[$tag]')).toList();
    }

    return filteredLogs;
  }

  static Future<String?> getLogFile() async {
    try {
      return await _logFile?.readAsString();
    } catch (e) {
      developer.log('Failed to read log file: $e');
      return null;
    }
  }

  static Future<void> clearLogs() async {
    _logs.clear();
    try {
      await _logFile?.writeAsString('');
    } catch (e) {
      developer.log('Failed to clear log file: $e');
    }
  }

  static Future<void> exportLogs() async {
    final logs = getLogs();
    final timestamp = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
    final directory = await getApplicationDocumentsDirectory();
    final exportFile = File('${directory.path}/logs_export_$timestamp.txt');
    
    await exportFile.writeAsString(logs.join('\n'));
    info('Logs exported to: ${exportFile.path}');
  }
}
