import 'dart:async';
import 'package:flutter/foundation.dart';

class LogEntry {
  final String message;
  final DateTime timestamp;
  final LogLevel level;

  LogEntry(this.message, this.level) : timestamp = DateTime.now();

  @override
  String toString() {
    return '${timestamp.hour}:${timestamp.minute}:${timestamp.second} [${level.name}] $message';
  }
}

enum LogLevel { info, warning, error, process }

class LogService {
  static final LogService _instance = LogService._internal();
  factory LogService() => _instance;
  LogService._internal();

  final List<LogEntry> _logs = [];
  final _logStreamController = StreamController<List<LogEntry>>.broadcast();

  // Active processes being tracked
  final Map<String, String> _activeProcesses = {};
  final _processStreamController =
      StreamController<Map<String, String>>.broadcast();

  Stream<List<LogEntry>> get logStream => _logStreamController.stream;
  Stream<Map<String, String>> get processStream =>
      _processStreamController.stream;
  List<LogEntry> get logs => List.unmodifiable(_logs);
  Map<String, String> get activeProcesses => Map.unmodifiable(_activeProcesses);

  void log(String message, {LogLevel level = LogLevel.info}) {
    final entry = LogEntry(message, level);
    _logs.add(entry);
    _logStreamController.add(_logs);

    // Also print to console in debug mode
    if (kDebugMode) {
      print('${entry.timestamp.toIso8601String()} [${level.name}] $message');
    }
  }

  void startProcess(String processId, String description) {
    _activeProcesses[processId] = description;
    _processStreamController.add(_activeProcesses);
    log('Started: $description', level: LogLevel.process);
  }

  void updateProcess(String processId, String status) {
    if (_activeProcesses.containsKey(processId)) {
      _activeProcesses[processId] = status;
      _processStreamController.add(_activeProcesses);
    }
  }

  void endProcess(String processId, {String finalStatus = 'Completed'}) {
    if (_activeProcesses.containsKey(processId)) {
      final description = _activeProcesses[processId];
      if (description != null) {
        log('Completed: $description - $finalStatus', level: LogLevel.process);
      }
      _activeProcesses.remove(processId);
      _processStreamController.add(_activeProcesses);
    }
  }

  void dispose() {
    _logStreamController.close();
    _processStreamController.close();
  }
}
