import 'package:flutter/material.dart';

import 'core/theme/flo_theme.dart';
import 'services/database_service.dart';
import 'services/auth_service.dart';
import 'ui/shell.dart';
import 'ui/onboarding/welcome_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize SQLite database
  await DatabaseService.database;

  runApp(const FlowspaceApp());
}

class FlowspaceApp extends StatelessWidget {
  const FlowspaceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '',
      debugShowCheckedModeBanner: false,
      theme: FloTheme.darkTheme,
      home: FutureBuilder<Map<String, dynamic>?>(
        future: AuthService.getCurrentUser(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          final user = snapshot.data;
          if (user == null) {
            // No user - show onboarding
            return const WelcomeScreen();
          }

          // User exists - go to main app
          return const FlowShell();
        },
      ),
    );
  }
}
