import 'package:flutter/material.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';

class AcrylicTheme {
  static Future<void> initialize() async {
    await Window.initialize();
    await Window.setEffect(
      effect: WindowEffect.acrylic,
      color: const Color(0xCC222222),
      dark: true,
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF7B61FF), // FlowSpace Purple
        surface: Colors.transparent, // Important for Acrylic
        background: Colors.transparent, // Important for Acrylic
      ),
      scaffoldBackgroundColor: Colors.transparent,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
    );
  }
}
