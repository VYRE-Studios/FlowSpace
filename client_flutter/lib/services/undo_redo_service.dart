import 'package:flutter/foundation.dart';

abstract class UndoableAction {
  void execute();
  void undo();
  String get description;
}

class UndoRedoService {
  static final UndoRedoService instance = UndoRedoService._();
  UndoRedoService._();

  final List<UndoableAction> _undoStack = [];
  final List<UndoableAction> _redoStack = [];
  final int _maxStackSize = 100;

  final ValueNotifier<bool> canUndo = ValueNotifier<bool>(false);
  final ValueNotifier<bool> canRedo = ValueNotifier<bool>(false);

  void execute(UndoableAction action) {
    action.execute();
    _undoStack.add(action);
    _redoStack.clear();
    
    if (_undoStack.length > _maxStackSize) {
      _undoStack.removeAt(0);
    }
    
    _updateNotifiers();
  }

  void undo() {
    if (_undoStack.isEmpty) return;
    
    final action = _undoStack.removeLast();
    action.undo();
    _redoStack.add(action);
    
    _updateNotifiers();
  }

  void redo() {
    if (_redoStack.isEmpty) return;
    
    final action = _redoStack.removeLast();
    action.execute();
    _undoStack.add(action);
    
    _updateNotifiers();
  }

  void clear() {
    _undoStack.clear();
    _redoStack.clear();
    _updateNotifiers();
  }

  void _updateNotifiers() {
    canUndo.value = _undoStack.isNotEmpty;
    canRedo.value = _redoStack.isNotEmpty;
  }

  String? get lastUndoDescription => 
      _undoStack.isNotEmpty ? _undoStack.last.description : null;
  
  String? get lastRedoDescription => 
      _redoStack.isNotEmpty ? _redoStack.last.description : null;
}
