import 'package:flutter/material.dart';

/// FLŌ Brand Theme
/// Premium dark theme with vibrant blue accents
class FloTheme {
  // Brand Colors
  static const Color floPrimary = Color(0xFF0B93FF); // Vibrant blue
  static const Color floSecondary = Color(0xFF00D9FF); // Cyan accent
  
  // Backgrounds
  static const Color bgPure = Color(0xFF000000); // Pure black
  static const Color bgElevated1 = Color(0xFF0A0A0A); // Subtle elevation
  static const Color bgElevated2 = Color(0xFF111111); // Cards
  static const Color bgElevated3 = Color(0xFF1A1A1A); // Dialogs
  
  // Surfaces
  static const Color surfaceHover = Color(0xFF1E1E1E);
  static const Color surfaceSelected = Color(0xFF252525);
  
  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB3B3B3);
  static const Color textTertiary = Color(0xFF666666);
  static const Color textDisabled = Color(0xFF404040);
  
  // Borders
  static const Color borderSubtle = Color(0xFF1A1A1A);
  static const Color borderDefault = Color(0xFF2A2A2A);
  static const Color borderHover = Color(0xFF404040);
  
  // Status Colors
  static const Color success = Color(0xFF00D97E);
  static const Color warning = Color(0xFFFFB800);
  static const Color error = Color(0xFFFF4D4D);
  static const Color info = Color(0xFF0B93FF);
  
  // Gradients
  static const LinearGradient floGradient = LinearGradient(
    colors: [floPrimary, floSecondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient floGradientVertical = LinearGradient(
    colors: [floPrimary, floSecondary],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  // Spacing
  static const double spacing2xs = 4.0;
  static const double spacingXs = 8.0;
  static const double spacingSm = 12.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;
  static const double spacing2xl = 48.0;
  static const double spacing3xl = 64.0;
  
  // Border Radius
  static const double radiusSm = 6.0;
  static const double radiusMd = 8.0;
  static const double radiusLg = 12.0;
  static const double radiusXl = 16.0;
  static const double radius2xl = 24.0;
  static const double radiusFull = 9999.0;
  
  // Elevation (shadows)
  static BoxShadow elevation1 = BoxShadow(
    color: Colors.black.withValues(alpha: 0.1),
    blurRadius: 4,
    offset: const Offset(0, 1),
  );
  
  static BoxShadow elevation2 = BoxShadow(
    color: Colors.black.withValues(alpha: 0.2),
    blurRadius: 8,
    offset: const Offset(0, 2),
  );
  
  static BoxShadow elevation3 = BoxShadow(
    color: Colors.black.withValues(alpha: 0.3),
    blurRadius: 16,
    offset: const Offset(0, 4),
  );
  
  // Typography
  static const String fontFamily = 'Inter';
  
  static const TextStyle heading1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 48,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    letterSpacing: -0.5,
  );
  
  static const TextStyle heading2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 36,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    letterSpacing: -0.5,
  );
  
  static const TextStyle heading3 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    letterSpacing: -0.25,
  );
  
  static const TextStyle heading4 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );
  
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: textPrimary,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textPrimary,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: textSecondary,
  );
  
  static const TextStyle labelLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    letterSpacing: 0.5,
  );
  
  static const TextStyle labelMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    letterSpacing: 0.5,
  );
  
  static const TextStyle labelSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 10,
    fontWeight: FontWeight.w600,
    color: textSecondary,
    letterSpacing: 0.5,
  );
  
  // Complete Material ThemeData
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      
      // Colors
      primaryColor: floPrimary,
      colorScheme: const ColorScheme.dark(
        primary: floPrimary,
        secondary: floSecondary,
        surface: bgElevated2,
        error: error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
        onError: Colors.white,
      ),
      
      scaffoldBackgroundColor: bgPure,
      canvasColor: bgElevated2,
      cardColor: bgElevated2,
      dividerColor: borderSubtle,
      
      // Typography
      fontFamily: fontFamily,
      textTheme: const TextTheme(
        displayLarge: heading1,
        displayMedium: heading2,
        displaySmall: heading3,
        headlineMedium: heading4,
        bodyLarge: bodyLarge,
        bodyMedium: bodyMedium,
        bodySmall: bodySmall,
        labelLarge: labelLarge,
        labelMedium: labelMedium,
        labelSmall: labelSmall,
      ),
      
      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: bgPure,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: heading4,
      ),
      
      // Card
      cardTheme: CardThemeData(
        color: bgElevated2,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: const BorderSide(color: borderSubtle, width: 1),
        ),
      ),
      
      // Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: floPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: labelLarge,
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: const BorderSide(color: borderDefault),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: labelLarge,
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: floPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: labelLarge,
        ),
      ),
      
      // Input
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgElevated2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: borderDefault),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: borderDefault),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: floPrimary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: bodyMedium.copyWith(color: textTertiary),
      ),
      
      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: bgElevated3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXl),
        ),
        titleTextStyle: heading3,
      ),
      
      // Icon
      iconTheme: const IconThemeData(
        color: textPrimary,
        size: 24,
      ),
      
      // Divider
      dividerTheme: const DividerThemeData(
        color: borderSubtle,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
