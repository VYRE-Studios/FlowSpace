import 'package:flutter/material.dart';

final ThemeData flowspaceTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: Colors.black,
  fontFamily: 'Inter',
  colorScheme: ColorScheme.dark(
    primary: Colors.blueAccent,
    secondary: Colors.cyanAccent,
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.black,
    elevation: 0,
    titleTextStyle: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
  ),
  textTheme: TextTheme(
    bodyMedium: TextStyle(fontSize: 15),
    bodyLarge: TextStyle(fontSize: 16),
  ),
  cardTheme: CardThemeData(
    color: const Color(0xFF1A1A1D),
    elevation: 2,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.blueAccent,
      foregroundColor: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  ),
);
