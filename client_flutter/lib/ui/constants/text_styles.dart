import 'package:flutter/material.dart';
import 'colors.dart'; // Your AppColors class

/// Premium Minimal Typography for FlowSpace v2
/// Engineered to remove all pure white and enforce brand ladder consistency
class AppTextStyles {
  // ═══════════════════════════════════════════════════════════════
  // DISPLAY — Big, quiet, premium titles
  // ═══════════════════════════════════════════════════════════════

  static const displayLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 0.4,
  );

  static const displayMedium = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 0.3,
  );

  static const displaySmall = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 0.25,
  );

  // ═══════════════════════════════════════════════════════════════
  // HEADINGS — Section labels and UI anchors
  // ═══════════════════════════════════════════════════════════════

  static const headingLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    letterSpacing: 0.3,
  );

  static const headingMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    letterSpacing: 0.25,
  );

  static const headingSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    letterSpacing: 0.2,
  );

  // ═══════════════════════════════════════════════════════════════
  // BODY TEXT — Main content
  // ═══════════════════════════════════════════════════════════════

  static const bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textTertiary,
    height: 1.35,
  );

  static const bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textTertiary,
    height: 1.33,
  );

  static const bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textMeta,
  );

  // ═══════════════════════════════════════════════════════════════
  // LABELS — Buttons, UI items
  // ═══════════════════════════════════════════════════════════════

  static const labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  static const labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  static const labelSmall = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: AppColors.textMeta,
  );

  // ═══════════════════════════════════════════════════════════════
  // CAPTIONS — Metadata, timestamps
  // ═══════════════════════════════════════════════════════════════

  static const caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textMeta,
  );

  static const captionSmall = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w400,
    color: AppColors.textMeta,
  );

  // ═══════════════════════════════════════════════════════════════
  // MESSAGES — Content inside chat or logs
  // ═══════════════════════════════════════════════════════════════

  static const messageContent = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.38,
  );

  static const messageAuthor = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const messageTimestamp = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AppColors.textMeta,
  );

  // ═══════════════════════════════════════════════════════════════
  // INPUTS — Textfields, shared inputs
  // ═══════════════════════════════════════════════════════════════

  static const inputText = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static const inputHint = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textMeta,
  );

  // ═══════════════════════════════════════════════════════════════
  // CODE — Monospace blocks
  // ═══════════════════════════════════════════════════════════════

  static const code = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    fontFamily: 'monospace',
  );

  static const codeSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AppColors.textMeta,
    fontFamily: 'monospace',
  );

  // ═══════════════════════════════════════════════════════════════
  // STATES — Success, warning, error
  // ═══════════════════════════════════════════════════════════════

  static const error = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.error,
  );

  static const success = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.success,
  );

  static const warning = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.warning,
  );
}

