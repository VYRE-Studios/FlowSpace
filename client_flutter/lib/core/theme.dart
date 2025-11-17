import 'package:flutter/material.dart';

const _backgroundBlack = Color(0xFF000000);
const _surfaceCharcoal = Color(0xFF1A1A1A);
const _electricBlue = Color(0xFF0066FF);
const _emeraldAccent = Color(0xFF10B981);
const flowCyan = Color(0xFF00C2E0); // FlowSpace brand cyan

final ColorScheme flowColorScheme = const ColorScheme.dark(
  background: _backgroundBlack,
  surface: _surfaceCharcoal,
  primary: _electricBlue,
  secondary: _emeraldAccent,
  onPrimary: Colors.white,
  onSurface: Colors.white,
);

final ThemeData flowTheme = ThemeData(
  useMaterial3: true,
  colorScheme: flowColorScheme,
  scaffoldBackgroundColor: _backgroundBlack,
  fontFamily: 'Inter',
  textTheme: const TextTheme(
    bodyMedium: TextStyle(fontSize: 14, height: 1.6, color: Colors.white),
    titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
  ),
  dividerColor: const Color.fromRGBO(255, 255, 255, 0.08),
  visualDensity: VisualDensity.adaptivePlatformDensity,
);

