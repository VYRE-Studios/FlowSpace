import 'dart:async';
import 'dart:isolate';
import 'error_logging_service.dart';

enum WorkerTaskType {
  summarization,
  indexing,
  analysis,
  export,
}

class WorkerTask {
  final String id;
  final WorkerTaskType type;
  final Map<String, dynamic> data;
  final DateTime createdAt;

  WorkerTask({
    required this.id,
    required this.type,
    required this.data,
  }) : createdAt = DateTime.now();
}

class WorkerResult {
  final String taskId;
  final bool success;
  final dynamic data;
  final String? error;

  WorkerResult({
    required this.taskId,
    required this.success,
    this.data,
    this.error,
  });
}

class BackgroundWorkerService {
  static final BackgroundWorkerService instance = BackgroundWorkerService._();
  BackgroundWorkerService._();

  Isolate? _isolate;
  SendPort? _sendPort;
  ReceivePort? _receivePort;
  final Map<String, Completer<WorkerResult>> _pendingTasks = {};

  Future<void> init() async {
    _receivePort = ReceivePort();

    _receivePort!.listen((message) {
      if (message is SendPort) {
        _sendPort = message;
        ErrorLoggingService.instance.info('Background worker initialized');
      } else if (message is WorkerResult) {
        final completer = _pendingTasks.remove(message.taskId);
        if (completer != null && !completer.isCompleted) {
          completer.complete(message);
        }
      }
    });

    _isolate = await Isolate.spawn(_workerEntryPoint, _receivePort!.sendPort);
  }

  static void _workerEntryPoint(SendPort mainSendPort) {
    final workerReceivePort = ReceivePort();
    mainSendPort.send(workerReceivePort.sendPort);

    workerReceivePort.listen((message) async {
      if (message is! WorkerTask) return;

      try {
        final result = await _processTask(message);
        mainSendPort.send(WorkerResult(
          taskId: message.id,
          success: true,
          data: result,
        ));
      } catch (e) {
        mainSendPort.send(WorkerResult(
          taskId: message.id,
          success: false,
          error: e.toString(),
        ));
      }
    });
  }

  static Future<dynamic> _processTask(WorkerTask task) async {
    switch (task.type) {
      case WorkerTaskType.summarization:
        await Future.delayed(const Duration(seconds: 2));
        return {'summary': 'Processed summarization'};

      case WorkerTaskType.indexing:
        await Future.delayed(const Duration(seconds: 1));
        return {'indexed': task.data['items']?.length ?? 0};

      case WorkerTaskType.analysis:
        await Future.delayed(const Duration(seconds: 3));
        return {'insights': ['insight1', 'insight2']};

      case WorkerTaskType.export:
        await Future.delayed(const Duration(seconds: 2));
        return {'exported': true, 'path': '/tmp/export.json'};
    }
  }

  Future<WorkerResult> submitTask(WorkerTask task) async {
    if (_sendPort == null) {
      throw Exception('Background worker not initialized');
    }

    final completer = Completer<WorkerResult>();
    _pendingTasks[task.id] = completer;

    _sendPort!.send(task);

    return completer.future.timeout(
      const Duration(minutes: 5),
      onTimeout: () {
        _pendingTasks.remove(task.id);
        return WorkerResult(
          taskId: task.id,
          success: false,
          error: 'Task timeout',
        );
      },
    );
  }

  void dispose() {
    _isolate?.kill(priority: Isolate.immediate);
    _receivePort?.close();
  }
}
