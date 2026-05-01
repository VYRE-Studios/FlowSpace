import 'package:flutter/material.dart';

/// Unified spacing constants for consistent UI rhythm across FlowSpace
/// 
/// Use these instead of hard-coded EdgeInsets to maintain visual consistency
class AppSpacing {
  // Standard padding values
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;

  // Common padding presets
  static const EdgeInsets paddingXS = EdgeInsets.all(xs);
  static const EdgeInsets paddingSM = EdgeInsets.all(sm);
  static const EdgeInsets paddingMD = EdgeInsets.all(md);
  static const EdgeInsets paddingLG = EdgeInsets.all(lg);
  static const EdgeInsets paddingXL = EdgeInsets.all(xl);
  static const EdgeInsets paddingXXL = EdgeInsets.all(xxl);

  // Section padding (standard for most containers)
  static const EdgeInsets paddingSection = EdgeInsets.all(lg);

  // Horizontal padding
  static const EdgeInsets paddingHorizontalXS = EdgeInsets.symmetric(horizontal: xs);
  static const EdgeInsets paddingHorizontalSM = EdgeInsets.symmetric(horizontal: sm);
  static const EdgeInsets paddingHorizontalMD = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets paddingHorizontalLG = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets paddingHorizontalXL = EdgeInsets.symmetric(horizontal: xl);

  // Vertical padding
  static const EdgeInsets paddingVerticalXS = EdgeInsets.symmetric(vertical: xs);
  static const EdgeInsets paddingVerticalSM = EdgeInsets.symmetric(vertical: sm);
  static const EdgeInsets paddingVerticalMD = EdgeInsets.symmetric(vertical: md);
  static const EdgeInsets paddingVerticalLG = EdgeInsets.symmetric(vertical: lg);
  static const EdgeInsets paddingVerticalXL = EdgeInsets.symmetric(vertical: xl);

  // Standard spacing for SizedBox
  static const SizedBox spaceXS = SizedBox(height: xs, width: xs);
  static const SizedBox spaceSM = SizedBox(height: sm, width: sm);
  static const SizedBox spaceMD = SizedBox(height: md, width: md);
  static const SizedBox spaceLG = SizedBox(height: lg, width: lg);
  static const SizedBox spaceXL = SizedBox(height: xl, width: xl);
  static const SizedBox spaceXXL = SizedBox(height: xxl, width: xxl);

  // Horizontal spacing
  static const SizedBox spaceHorizontalXS = SizedBox(width: xs);
  static const SizedBox spaceHorizontalSM = SizedBox(width: sm);
  static const SizedBox spaceHorizontalMD = SizedBox(width: md);
  static const SizedBox spaceHorizontalLG = SizedBox(width: lg);
  static const SizedBox spaceHorizontalXL = SizedBox(width: xl);

  // Vertical spacing
  static const SizedBox spaceVerticalXS = SizedBox(height: xs);
  static const SizedBox spaceVerticalSM = SizedBox(height: sm);
  static const SizedBox spaceVerticalMD = SizedBox(height: md);
  static const SizedBox spaceVerticalLG = SizedBox(height: lg);
  static const SizedBox spaceVerticalXL = SizedBox(height: xl);
  static const SizedBox spaceVerticalXXL = SizedBox(height: xxl);
}
