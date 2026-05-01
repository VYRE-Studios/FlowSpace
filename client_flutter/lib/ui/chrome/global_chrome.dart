import 'package:flutter/material.dart';
import '../constants/colors.dart';

/// Global chrome wrapper - Δ-PM2.E
/// Engineered carbon bezel that wraps entire workspace
class GlobalChrome extends StatelessWidget {
  final Widget topBar;
  final Widget child;

  const GlobalChrome({
    super.key,
    required this.topBar,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 56,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.bgChromeHighlight,
                AppColors.bgChrome,
              ],
            ),
            border: Border(
              bottom: BorderSide(
                color: AppColors.borderChrome,
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.chromeShadow,
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: topBar,
        ),
        Expanded(child: child),
      ],
    );
  }
}
