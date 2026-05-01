import 'package:flutter/material.dart';
import '../views/dashboard_view.dart';

/// Dashboard screen - wraps DashboardView for centralized routing
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const DashboardView();
  }
}
