import 'dart:async';
import 'package:flutter/foundation.dart';

class AutosaveService {
  static final AutosaveService instance = AutosaveService._();
  AutosaveService._();

  Timer? _autosaveTimer;
  bool _isDirty = false;
  DateTime? _lastSaved;
  
  final ValueNotifier<String> saveStatus = ValueNotifier<String>('All changes saved');
  final ValueNotifier<bool> isSaving = ValueNotifier<bool>(false);

  Function()? _saveCallback;

  void init({
    required Function() onSave,
    Duration interval = const Duration(seconds: 30),
  }) {
    _saveCallback = onSave;
    _autosaveTimer?.cancel();
    _autosaveTimer = Timer.periodic(interval, (_) {
      if (_isDirty && !isSaving.value) {
        _performSave();
      }
    });
  }

  void markDirty() {
    _isDirty = true;
    saveStatus.value = 'Unsaved changes';
  }

  Future<void> saveNow() async {
    await _performSave();
  }

  Future<void> _performSave() async {
    if (_saveCallback == null || !_isDirty) return;

    isSaving.value = true;
    saveStatus.value = 'Saving...';

    try {
      await _saveCallback!();
      _isDirty = false;
      _lastSaved = DateTime.now();
      saveStatus.value = 'All changes saved';
    } catch (e) {
      saveStatus.value = 'Save failed';
      print('Autosave error: $e');
    } finally {
      isSaving.value = false;
    }
  }

  void dispose() {
    _autosaveTimer?.cancel();
    _autosaveTimer = null;
    _saveCallback = null;
    saveStatus.dispose();
    isSaving.dispose();
  }

  DateTime? get lastSaved => _lastSaved;
  bool get hasPendingChanges => _isDirty;
}
