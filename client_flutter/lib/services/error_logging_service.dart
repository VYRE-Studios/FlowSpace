import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

enum LogLevel {
  debug,
  info,
  warning,
  error,
  fatal,
}

class ErrorLoggingService {
  static final ErrorLoggingService instance = ErrorLoggingService._();
  ErrorLoggingService._();

  File? _logFile;
  final List<String> _logBuffer = [];
  final int _maxBufferSize = 100;
  Timer? _flushTimer;

  Future<void> init() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final logsDir = Directory('${appDir.path}/VyreVault/Flo/logs');
      if (!await logsDir.exists()) {
        await logsDir.create(recursive: true);
      }

      final timestamp = DateTime.now().toIso8601String().split('T')[0];
      _logFile = File('${logsDir.path}/app_$timestamp.log');

      _flushTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        _flush();
      });
    } catch (e) {
      print('Failed to initialize logging: $e');
    }
  }

  void log(String message, {LogLevel level = LogLevel.info}) {
    final timestamp = DateTime.now().toIso8601String();
    final levelStr = level.name.toUpperCase().padRight(7);
    final logLine = '$timestamp [$levelStr] $message';

    print(logLine);
    _logBuffer.add(logLine);

    if (_logBuffer.length >= _maxBufferSize) {
      _flush();
    }
  }

  void debug(String message) => log(message, level: LogLevel.debug);
  void info(String message) => log(message, level: LogLevel.info);
  void warning(String message) => log(message, level: LogLevel.warning);
  void error(String message, {Object? error, StackTrace? stackTrace}) {
    final fullMessage = error != null
        ? '$message: $error${stackTrace != null ? '\n$stackTrace' : ''}'
        : message;
    log(fullMessage, level: LogLevel.error);
  }
  void fatal(String message) => log(message, level: LogLevel.fatal);

  void _flush() {
    if (_logBuffer.isEmpty || _logFile == null) return;

    try {
      final content = _logBuffer.join('\n') + '\n';
      _logFile!.writeAsStringSync(content, mode: FileMode.append);
      _logBuffer.clear();
    } catch (e) {
      print('Failed to flush logs: $e');
    }
  }

  void dispose() {
    _flush();
    _flushTimer?.cancel();
  }
}
