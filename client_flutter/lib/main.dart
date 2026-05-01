import 'package:flutter/material.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:provider/provider.dart';

import 'core/theme/flo_theme.dart';
import 'services/database_service.dart';
import 'services/auth_service.dart';
import 'services/chat_integration_helper.dart';
import 'services/notification_service.dart';
import 'services/flo_update_service.dart';
import 'services/error_logging_service.dart';
import 'services/analytics_service.dart';
import 'services/keyboard_shortcuts_service.dart';
import 'services/background_worker_service.dart';
import 'services/project_registry.dart';
import 'services/project_loader.dart';
import 'services/flowspace_config.dart';
import 'sync/sync_manager.dart';
import 'state/project_state.dart';
import 'state/active_workspace_state.dart';
import 'state/tool_state.dart';
import 'state/channel_context.dart';
import 'navigation/app_router.dart';
import 'ui/shell/app_shell.dart';
import 'ui/onboarding/welcome_screen.dart';
import 'ui/screens/user_picker_screen.dart';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'ui/theme/acrylic_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Acrylic Theme (Windows 11 effects)
  await AcrylicTheme.initialize();

  // Initialize error logging first
  await ErrorLoggingService.instance.init();
  ErrorLoggingService.instance.info('FlowSpace v2.0.0 starting...');

  // Initialize SQLite database and default local account for offline builds.
  await DatabaseService.database;
  await AuthService.ensureDefaultLocalAccount();

  // Initialize notification service
  await NotificationService.instance.init();

  // Initialize background worker for heavy tasks
  await BackgroundWorkerService.instance.init();

  // Initialize keyboard shortcuts
  KeyboardShortcutsService.instance.init();

  // Initialize real-time sync system
  _initializeSyncSystem();

  // Fire and forget update check on startup (non-blocking)
  FloUpdateService.checkAndApplyUpdates();

  // Initialize project persistence system (non-blocking)
  _initializeProjectPersistence();

  runApp(const FlowspaceApp());

  // Configure Custom Window Frame
  doWhenWindowReady(() {
    const initialSize = Size(1280, 800);
    appWindow.minSize = const Size(1024, 768);
    appWindow.size = initialSize;
    appWindow.alignment = Alignment.center;
    appWindow.title = "FlowSpace";
    appWindow.show();
  });
}

class FlowspaceApp extends StatelessWidget {
  const FlowspaceApp({super.key});

  static const bool _enableTestUserPicker = bool.fromEnvironment(
    'FLOWSPACE_ENABLE_TEST_USER_PICKER',
    defaultValue: false,
  );

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ActiveWorkspaceState()),
        ChangeNotifierProvider(create: (_) => ToolState()),
        ChangeNotifierProvider(create: (_) => ChannelContext()),
        ChangeNotifierProvider(
          create: (context) {
            final projectState = ProjectState();
            final activeWorkspace = context.read<ActiveWorkspaceState>();
            final channelContext = context.read<ChannelContext>();

            // Wire callback to sync project changes into routing state AND load channels
            projectState.setProjectChangeCallback((project) {
              activeWorkspace.setActiveProject(project);
              if (project != null) {
                channelContext.loadProjectChannels(project.projectId);
              } else {
                channelContext.clear();
              }
            });
            return projectState;
          },
        ),
      ],
      child: OverlaySupport.global(
        child: MaterialApp(
          title: 'FLŌ',
          debugShowCheckedModeBanner: false,
          theme: FloTheme.darkTheme,
          routes: AppRouter.routes,
          onUnknownRoute: AppRouter.onUnknownRoute,
          home: FutureBuilder<_StartupDestination>(
            future: _resolveStartupDestination(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              final destination = snapshot.data;
              if (destination == null ||
                  destination.kind == _StartupDestinationKind.welcome) {
                return const WelcomeScreen();
              }

              if (destination.kind == _StartupDestinationKind.testPicker) {
                return const UserPickerScreen();
              }

              final user = destination.user;
              if (user == null) {
                return const WelcomeScreen();
              }

              _initializeChatServices(user);

              return const AppShell();
            },
          ),
        ),
      ),
    );
  }

  static Future<_StartupDestination> _resolveStartupDestination() async {
    try {
      final user = await AuthService.getCurrentUser();
      if (user != null) {
        return _StartupDestination.authenticated(user);
      }

      if (_enableTestUserPicker) {
        return const _StartupDestination.testPicker();
      }

      return const _StartupDestination.welcome();
    } catch (e) {
      ErrorLoggingService.instance.error(
        'Error resolving startup destination',
        error: e,
      );
      return const _StartupDestination.welcome();
    }
  }

  void _initializeChatServices(Map<String, dynamic> user) async {
    try {
      await ChatIntegrationHelper.initialize(
        userId: user['id'] as String,
        username:
            user['email'] as String? ??
            user['displayName'] as String? ??
            'user',
      );

      // Initialize analytics with user ID
      AnalyticsService.instance.init(userId: user['id'] as String);
      AnalyticsService.instance.track(
        'app_started',
        properties: {'version': '1.1.0'},
      );

      ErrorLoggingService.instance.info(
        'Chat services initialized for user: ${user['id']}',
      );
    } catch (e) {
      ErrorLoggingService.instance.error(
        'Error initializing chat services',
        error: e,
      );
    }
  }
}

enum _StartupDestinationKind { authenticated, welcome, testPicker }

class _StartupDestination {
  final _StartupDestinationKind kind;
  final Map<String, dynamic>? user;

  const _StartupDestination._(this.kind, [this.user]);

  const _StartupDestination.authenticated(Map<String, dynamic> user)
    : this._(_StartupDestinationKind.authenticated, user);

  const _StartupDestination.welcome() : this._(_StartupDestinationKind.welcome);

  const _StartupDestination.testPicker()
    : this._(_StartupDestinationKind.testPicker);
}

/// Initialize real-time sync system
void _initializeSyncSystem() async {
  try {
    if (!FlowSpaceConfig.isConfigured) {
      print('[SyncSystem] WARNING: FlowSpace backend URL not configured!');
      print(
        '[SyncSystem] Update lib/services/flowspace_config.dart with your Render URL',
      );
      return;
    }

    ErrorLoggingService.instance.info('Initializing real-time sync system...');

    final user = await AuthService.getCurrentUser();
    if (user == null) {
      print('[SyncSystem] No user logged in - skipping sync initialization');
      return;
    }

    // Initialize SyncManager with project scope
    SyncManager.instance.initialize(
      url: FlowSpaceConfig.syncUrl,
      clientId: user['id'] as String,
    );

    ErrorLoggingService.instance.info('Real-time sync system initialized');
  } catch (e) {
    ErrorLoggingService.instance.error(
      'Error initializing sync system',
      error: e,
    );
  }
}

/// Initialize project persistence system - scan and load projects
void _initializeProjectPersistence() async {
  try {
    ErrorLoggingService.instance.info(
      'Initializing project persistence system...',
    );

    final registryService = ProjectRegistryService();
    final authToken = await AuthService.getAuthToken();

    final loaderService = ProjectLoaderService(
      registryService: registryService,
      apiBaseUrl: FlowSpaceConfig.apiBaseUrl,
      authToken: authToken,
    );

    // Scan and load all projects (non-blocking background task)
    await loaderService.scanAndLoadProjects();

    ErrorLoggingService.instance.info('Project persistence system initialized');
  } catch (e) {
    ErrorLoggingService.instance.error(
      'Error initializing project persistence',
      error: e,
    );
  }
}
