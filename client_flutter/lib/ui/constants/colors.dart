import 'package:flutter/material.dart';

/// Premium Minimal Design System - FlowSpace v2.0.0
/// Meticulously engineered color palette for Batmobile-grade stealth aesthetic
class AppColors {
  // ═══════════════════════════════════════════════════════════════════════════
  // BACKGROUNDS - Charcoal gradient with atmospheric depth
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Root background - top of gradient
  static const bgTop = Color(0xFF111317);
  
  /// Root background - bottom of gradient
  static const bgBottom = Color(0xFF0C0D0F);
  
  // ═══════════════════════════════════════════════════════════════════════════
  // SURFACES - Machined carbon panels with material definition
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Sidebar surface - distinct from background
  static const sidebar = Color(0xFF131416);
  
  /// Deeper carbon for sidebar - Δ-PM2.A
  static const bgSidebar = Color(0xFF0A0B0D);
  
  /// Sidebar item hover state - Δ-PM2.A
  static const sidebarItemHover = Color(0xFF1A1C20);
  
  /// Sidebar item active state - Δ-PM2.A
  static const sidebarItemActive = Color(0xFF111317);
  
  /// Header bar surface
  static const header = Color(0xFF121417);
  
  /// Card/panel surface - machined carbon
  static const card = Color(0xFF141618);
  
  /// Card primary background - Δ-PM2.B
  static const bgCardPrimary = Color(0xFF111317);
  
  /// Card raised background - Δ-PM2.B
  static const bgCardRaised = Color(0xFF171A1F);
  
  /// Card border color - Δ-PM2.B
  static const borderCard = Color(0xFF1F2227);
  
  /// Low shadow for cards - Δ-PM2.B
  static const shadowLow = Color.fromARGB(60, 0, 0, 0);
  
  /// Mid shadow for elevated cards - Δ-PM2.B
  static const shadowMid = Color.fromARGB(90, 0, 0, 0);
  
  // ═══════════════════════════════════════════════════════════════════════════
  // BUTTON SYSTEM - Δ-PM2.C Quick Action Overhaul
  // ═══════════════════════════════════════════════════════════════════════════
  
  // Primary button
  static const buttonPrimaryBg = Color(0xFF0E1624);
  static const buttonPrimaryHover = Color(0xFF152033);
  static const buttonPrimaryActive = Color(0xFF0B101A);
  static const buttonPrimaryBorder = Color(0xFF2D4EA2);
  
  // Secondary button
  static const buttonSecondaryBg = Color(0xFF16181C);
  static const buttonSecondaryHover = Color(0xFF1D2025);
  static const buttonSecondaryActive = Color(0xFF131417);
  static const buttonSecondaryBorder = Color(0xFF2A2D32);
  
  // Icon button
  static const buttonIconBg = Color(0xFF131417);
  static const buttonIconHover = Color(0xFF1B1D21);
  static const buttonIconActive = Color(0xFF101113);
  static const buttonIconBorder = Color(0xFF2A2D32);
  
  // Ghost button
  static const buttonGhostBg = Colors.transparent;
  static const buttonGhostHover = Color(0xFF1A1C20);
  static const buttonGhostActive = Color(0xFF131417);
  static const buttonGhostBorder = Color(0xFF2A2D32);
  
  // ═══════════════════════════════════════════════════════════════════════════
  // TEXT HIERARCHY - Premium typography with precise contrast
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Primary text - titles, headers - Darker Premium Grey
  static const textPrimary = Color(0xFFA8ACB2);
  
  /// Secondary text - section labels, important metadata - Darker Premium Grey
  static const textSecondary = Color(0xFF7C8087);
  
  /// Tertiary text - body text, subtitles - Darker Premium Grey
  static const textTertiary = Color(0xFF656A72);
  
  /// Meta text - timestamps, fine details - Darker Premium Grey
  static const textMeta = Color(0xFF4A4F56);
  
  /// Muted text - Δ-PM2.D typography ladder
  static const textMuted = Color(0xFF7A7F86);
  
  // ═══════════════════════════════════════════════════════════════════════════
  // CHROME SYSTEM - Δ-PM2.E Global Chrome & Top Bar
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Chrome background - carbon metal bezel
  static const bgChrome = Color(0xFF0D0E11);
  
  /// Chrome highlight - subtle gradient top
  static const bgChromeHighlight = Color(0xFF131417);
  
  /// Chrome border - refined separation
  static const borderChrome = Color(0xFF1C1E22);
  
  /// Chrome shadow - elevated depth
  static const chromeShadow = Color.fromARGB(100, 0, 0, 0);
  
  // ═══════════════════════════════════════════════════════════════════════════
  // ACCENTS - Controlled color usage for premium feel
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Primary accent - selected states, actions, links
  static const primary = Color(0xFF2563EB);
  
  /// Accent blue alias for sidebar active states - Δ-PM2.A
  static const accentBlue = Color(0xFF2563EB);
  
  /// Premium green - presence indicator, success states
  static const accentGreen = Color(0xFF45D37C);
  
  /// Legacy primary for backward compatibility
  static const primaryDark = Color(0xFF1E40AF);
  static const primaryLight = Color(0xFF3B82F6);
  
  // ═══════════════════════════════════════════════════════════════════════════
  // BORDERS - Precise opacity for subtle separation
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Softest border - 5% white (#FFFFFF0D)
  static const borderSofter = Color(0x0DFFFFFF);
  
  /// Soft border - 6% white (#FFFFFF0F) - sidebar, hover states
  static const borderSoft = Color(0x0FFFFFFF);
  
  /// Default border - 10% white (#FFFFFF1A)
  static const borderDefault = Color(0x1AFFFFFF);
  
  /// Low contrast border - Δ-PM2.A sidebar separation
  static const borderLow = Color(0xFF1C1E22);
  
  /// Strong border - 25% white for emphasis
  static const borderStrong = Color(0x40FFFFFF);
  
  // ═══════════════════════════════════════════════════════════════════════════
  // SEMANTIC COLORS - Status indicators
  // ═══════════════════════════════════════════════════════════════════════════
  
  static const success = Color(0xFF45D37C);
  static const successDim = Color(0xFF2A9D2A);
  
  static const error = Color(0xFFFF4444);
  static const errorDim = Color(0xFF9D2A2A);
  
  static const warning = Color(0xFFFFAA00);
  static const warningDim = Color(0xFF9D6600);
  
  static const info = Color(0xFF2563EB);
  static const infoDim = Color(0xFF1E40AF);
  
  // ═══════════════════════════════════════════════════════════════════════════
  // INTERACTIVE STATES - Precision engineered hover/press feedback
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Hover overlay - 3% white
  static final hoverOverlay = Colors.white.withValues(alpha: 0.03);
  
  /// Pressed overlay - 6% white
  static final pressedOverlay = Colors.white.withValues(alpha: 0.06);
  
  /// Selected overlay - 10% primary color
  static final selectedOverlay = primary.withValues(alpha: 0.10);
  
  // ═══════════════════════════════════════════════════════════════════════════
  // LEGACY COMPATIBILITY - Maintain existing functionality
  // ═══════════════════════════════════════════════════════════════════════════
  
  static const backgroundPrimary = bgBottom;
  static const backgroundSecondary = sidebar;
  static const backgroundTertiary = card;
  
  static final surfaceOverlay5 = Colors.white.withValues(alpha: 0.05);
  static final surfaceOverlay10 = Colors.white.withValues(alpha: 0.10);
  static final surfaceOverlay15 = Colors.white.withValues(alpha: 0.15);
  static final surfaceOverlay20 = Colors.white.withValues(alpha: 0.20);
  
  static const textDisabled = Color(0x61FFFFFF);
  
  static final borderSubtle = borderSofter;
  
  static final dividerLight = borderSofter;
  static final dividerDefault = borderSoft;
  static final dividerStrong = borderDefault;
  
  static final mentionBackground = primary.withValues(alpha: 0.15);
  static const mentionBorder = primary;
  
  static final pinnedBackground = warning.withValues(alpha: 0.10);
  static const pinnedBorder = warning;
  
  static const bulletinCritical = error;
  static const bulletinHigh = warning;
  static const bulletinNormal = info;
  static const bulletinLow = textTertiary;
}

/// Premium shadows for machined carbon panels
class AppShadows {
  /// Card shadow - layered depth
  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.15),
      blurRadius: 6,
      offset: Offset(0, 2),
    ),
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.08),
      blurRadius: 24,
      offset: Offset(0, 12),
    ),
  ];
  
  /// Header shadow - subtle elevation
  static const List<BoxShadow> header = [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.3),
      blurRadius: 12,
      offset: Offset(0, 2),
    ),
  ];
}
