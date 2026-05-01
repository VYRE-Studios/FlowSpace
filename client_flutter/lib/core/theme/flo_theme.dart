import 'package:flutter/material.dart';
import '../../ui/constants/colors.dart';

/// FLŌ Brand Theme
/// Premium minimal dark theme with refined text hierarchy
class FloTheme {
  // Brand Colors - Premium Blue
  static const Color floPrimary = AppColors.primary; // Premium blue #2563EB
  static const Color floSecondary = Color(0xFF00D9FF); // Cyan accent
  
  // Backgrounds - Premium Charcoal Gradient
  static const Color bgPure = AppColors.bgBottom; // Charcoal gradient bottom
  static const Color bgElevated1 = AppColors.sidebar; // Sidebar surface
  static const Color bgElevated2 = AppColors.card; // Machined carbon cards
  static const Color bgElevated3 = Color(0xFF1A1A1A); // Dialogs
  
  // Surfaces
  static const Color surfaceHover = Color(0xFF1E1E1E);
  static const Color surfaceSelected = Color(0xFF252525);
  
  // Text Ladder - Premium Minimal Brand Colors
  // NO MORE PURE WHITE - refined hierarchy instead
  static const Color textPrimary   = AppColors.textPrimary;   // #E6E7E9 - main titles
  static const Color textSecondary = AppColors.textSecondary; // #B7BCC4 - section labels
  static const Color textTertiary  = AppColors.textTertiary;  // #8F949C - supporting text
  static const Color textMeta      = AppColors.textMeta;      // #5D6168 - timestamps
  static const Color textDisabled  = AppColors.textDisabled;  // Disabled state
  
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
  
  // LEGACY STATIC STYLES - UPDATED WITH BRAND TEXT COLORS
  static const TextStyle heading1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 48,
    fontWeight: FontWeight.w700,
    color: textPrimary,   // #E6E7E9 - NOT pure white
    letterSpacing: -0.5,
  );
  
  static const TextStyle heading2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 36,
    fontWeight: FontWeight.w700,
    color: textPrimary,   // #E6E7E9 - NOT pure white
    letterSpacing: -0.5,
  );
  
  static const TextStyle heading3 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w600,
    color: textPrimary,   // #E6E7E9 - NOT pure white
    letterSpacing: -0.25,
  );
  
  static const TextStyle heading4 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: textSecondary, // #B7BCC4 - section labels
  );
  
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: textTertiary,  // #8F949C - body text
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textTertiary,  // #8F949C - body text
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: textMeta,      // #5D6168 - timestamps
  );
  
  static const TextStyle labelLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: textSecondary, // #B7BCC4 - section labels
    letterSpacing: 0.5,
  );
  
  static const TextStyle labelMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: textSecondary, // #B7BCC4 - labels
    letterSpacing: 0.5,
  );
  
  // Sidebar-specific typography - Δ-PM2.A
  static const TextStyle textSidebar = TextStyle(
    fontFamily: fontFamily,
    fontSize: 10,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    color: textSecondary,
  );

  static const TextStyle textSidebarActive = TextStyle(
    fontFamily: fontFamily,
    fontSize: 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    color: AppColors.accentBlue,
  );

  static const TextStyle textSidebarSection = TextStyle(
    fontFamily: fontFamily,
    fontSize: 9,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.1,
    color: textMeta,
    height: 1.6,
  );

  static const TextStyle textCapsHeader = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.3,
    color: AppColors.textPrimary,
  );
  
  // Button typography - Δ-PM2.C
  static const TextStyle buttonPrimary = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 0.3,
  );

  static const TextStyle buttonSecondary = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    letterSpacing: 0.3,
  );
  
  // ═══════════════════════════════════════════════════════════════════════════
  // Δ-PM2.D UNIFIED TYPOGRAPHY LADDER
  // Complete typographic system for cinematic dark interfaces
  // ═══════════════════════════════════════════════════════════════════════════
  
  // DISPLAY TIER - Large headers, hero sections
  static const TextStyle displayLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.4,
    height: 1.15,
    color: AppColors.textPrimary,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 26,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
    height: 1.2,
    color: AppColors.textPrimary,
  );

  static const TextStyle displaySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.25,
    height: 1.22,
    color: AppColors.textPrimary,
  );

  // TITLE TIER - Card headers, section titles
  static const TextStyle titleLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.25,
    height: 1.25,
    color: AppColors.textPrimary,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
    height: 1.28,
    color: AppColors.textPrimary,
  );

  static const TextStyle titleSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.15,
    height: 1.3,
    color: AppColors.textPrimary,
  );

  // BODY TIER - Content text
  static const TextStyle bodyPrimary = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.35,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodySecondary = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.35,
    color: AppColors.textSecondary,
  );

  static const TextStyle bodyMuted = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.32,
    letterSpacing: 0.1,
    color: AppColors.textMuted,
  );

  // MICRO TIER - Captions, labels, metadata
  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    height: 1.3,
    color: AppColors.textSecondary,
  );

  static const TextStyle overline = TextStyle(
    fontFamily: fontFamily,
    fontSize: 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.1,
    height: 1.4,
    color: AppColors.textMuted,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.4,
    height: 1.3,
    color: AppColors.textSecondary,
  );
  
  // Complete Material ThemeData - Premium Minimal
  static ThemeData get darkTheme {
    final base = ThemeData.dark();
    
    // Apply text color baseline - all text defaults to textSecondary
    final textTheme = base.textTheme.apply(
      bodyColor: textSecondary,
      displayColor: textSecondary,
    );
    
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
        onSurface: textSecondary, // Default text baseline
        onError: Colors.white,
      ),
      
      scaffoldBackgroundColor: Colors.transparent, // Allow gradient backgrounds
      canvasColor: bgElevated2,
      cardColor: bgElevated2,
      dividerColor: borderSubtle,
      
      // Typography - Premium Minimal Text Hierarchy
      fontFamily: fontFamily,
      textTheme: textTheme.copyWith(
        // Big headers like "Welcome to FlowSpace"
        displayLarge: heading1,
        displayMedium: heading2,
        displaySmall: heading3,
        headlineMedium: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: textPrimary, // Premium primary for big headers
          letterSpacing: 0.4,
        ),
        // MISSING TITLE VARIANTS - ADDED
        titleLarge: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: 0.3,
        ),
        titleMedium: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textSecondary, // Soft secondary
          letterSpacing: 0.3,
        ),
        titleSmall: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textSecondary, // Section labels - THIS WAS MISSING!
          letterSpacing: 0.25,
        ),
        // Section labels: "Quick Actions", "Recent Activity"
        labelLarge: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textSecondary, // Section labels
          letterSpacing: 0.4,
        ),
        labelMedium: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textSecondary,
          letterSpacing: 0.5,
        ),
        labelSmall: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: textSecondary,
          letterSpacing: 0.5,
        ),
        // Body text inside cards
        bodyLarge: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: textTertiary, // Supporting text
        ),
        bodyMedium: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: textTertiary, // Body text
        ),
        // Meta text: "2 hours ago", timestamps
        bodySmall: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 11,
          fontWeight: FontWeight.w400,
          color: textMeta, // Timestamps, low priority
        ),
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
