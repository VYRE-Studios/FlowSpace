import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../services/vault_storage_service.dart';
import 'sticky_note.dart';
import 'stroke.dart';

class WhiteboardState {
  final String projectId;
  WhiteboardState(this.projectId);

  final List<StickyNote> stickies = [];
  final List<Stroke> strokes = [];

  void startStroke(Offset pos) {
    strokes.add(Stroke(points: [pos]));
  }

  void extendStroke(Offset pos) {
    if (strokes.isEmpty) return;
    strokes.last.points.add(pos);
  }

  Future<void> finishStroke() async {
    await save();
  }

  void addDefaultSticky({Offset center = const Offset(300, 200)}) {
    stickies.add(StickyNote(
      position: Offset(center.dx - 80, center.dy - 60),
      size: const Size(160, 120),
      text: 'Idea',
      color: const Color(0xFFFFF59D),
    ));
    // fire and forget save
    save();
  }

  Future<void> load() async {
    final jsonMap = await VaultStorageService.loadWhiteboard(projectId);
    if (jsonMap == null) return;
    final sticks = (jsonMap['stickies'] as List<dynamic>? ?? []);
    final strks = (jsonMap['strokes'] as List<dynamic>? ?? []);
    stickies
      ..clear()
      ..addAll(sticks.map((e) => StickyNote.fromJson(e as Map<String, dynamic>)));
    strokes
      ..clear()
      ..addAll(strks.map((e) => Stroke.fromJson(e as Map<String, dynamic>)));
  }

  Future<void> save() async {
    final map = {
      'stickies': stickies.map((s) => s.toJson()).toList(),
      'strokes': strokes.map((s) => s.toJson()).toList(),
    };
    await VaultStorageService.saveWhiteboard(projectId, jsonEncode(map));
  }
}
