import 'dart:convert';
import 'dart:io';
// import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'flo_update_service.dart';

/// Service for checking and managing application updates
class UpdateService {
  static const String _lastCheckKey = 'last_update_check';
  static const Duration _updateCheckInterval = Duration(hours: 24);

  /// Check if an update is available (uses Squirrel on Windows, backend API with GitHub fallback otherwise)
  static Future<UpdateInfo?> checkForUpdates({bool force = false}) async {
    try {
      // On Windows, try Squirrel auto-update first
      if (Platform.isWindows) {
        try {
          final updated = await FloUpdateService.checkAndApplyUpdates();
          if (updated) {
            // Squirrel update was applied - will take effect on next launch
            final packageInfoVersion = "2.1.0"; // Hardcoded for build fix
            return UpdateInfo(
              currentVersion: packageInfoVersion,
              latestVersion: 'Update will be applied on restart',
              downloadUrl: '',
              releaseNotes:
                  'Update downloaded and will be applied when you restart the app.',
              isRequired: false,
              updateSize: null,
            );
          }
        } catch (e) {
          print(
            'UpdateService: Squirrel update check failed, falling back: $e',
          );
        }
      }

      final prefs = await SharedPreferences.getInstance();
      final currentVersion = "2.1.0";
      final buildNumber = "20260501";

      // Check if we should skip update check (unless forced)
      if (!force) {
        final lastCheckStr = prefs.getString(_lastCheckKey);
        if (lastCheckStr != null) {
          final lastCheck = DateTime.parse(lastCheckStr);
          final now = DateTime.now();
          if (now.difference(lastCheck) < _updateCheckInterval) {
            return null; // Too soon to check again
          }
        }
      }

      // Try backend API first (caching + fallback support)
      final backendUrl = 'http://localhost:4000/api/v1/updates/check';
      final platform = Platform.isWindows
          ? 'windows'
          : (Platform.isMacOS ? 'macos' : 'linux');

      try {
        final backendResponse = await http
            .get(
              Uri.parse(
                '$backendUrl?version=$currentVersion&build=v$buildNumber&platform=$platform',
              ),
            )
            .timeout(const Duration(seconds: 10));

        if (backendResponse.statusCode == 200) {
          final data =
              json.decode(backendResponse.body) as Map<String, dynamic>;

          // Update last check time
          await prefs.setString(
            _lastCheckKey,
            DateTime.now().toIso8601String(),
          );

          final updateAvailable = data['updateAvailable'] as bool? ?? false;
          if (!updateAvailable) {
            print('UpdateService: No update available (via backend)');
            return null;
          }

          final latestVersion = data['latestVersion'] as String?;
          final downloadUrl = data['downloadUrl'] as String?;
          final releaseNotes = data['releaseNotes'] as String?;

          print(
            'UpdateService: Update available - $currentVersion -> $latestVersion (via backend)',
          );

          return UpdateInfo(
            currentVersion: currentVersion,
            latestVersion: latestVersion ?? currentVersion,
            downloadUrl: downloadUrl ?? '',
            releaseNotes: releaseNotes ?? '',
            isRequired: false,
            updateSize: null, // Backend doesn't provide size yet
          );
        }
      } catch (e) {
        print('UpdateService: Backend API failed, falling back to GitHub: $e');
      }

      // Fallback to GitHub Releases API
      final headers = <String, String>{'Accept': 'application/vnd.github+json'};

      final response = await http
          .get(
            Uri.parse(
              'https://api.github.com/repos/VYRE-Studios/FlowSpace/releases/latest',
            ),
            headers: headers,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        print('UpdateService: GitHub API returned ${response.statusCode}');
        return null;
      }

      final latestRelease = json.decode(response.body) as Map<String, dynamic>;

      // Skip drafts and prereleases
      if (latestRelease['draft'] == true ||
          latestRelease['prerelease'] == true) {
        print('UpdateService: Latest release is draft or prerelease');
        return null;
      }

      // Update last check time
      await prefs.setString(_lastCheckKey, DateTime.now().toIso8601String());

      final latestVersion = (latestRelease['tag_name'] as String?)
          ?.replaceFirst('v', '');
      print('UpdateService: Latest version from GitHub: $latestVersion');
      print('UpdateService: Current version: $currentVersion');

      // Find the .exe installer in assets
      String? downloadUrl;
      if (latestRelease['assets'] is List &&
          (latestRelease['assets'] as List).isNotEmpty) {
        final assets = latestRelease['assets'] as List;
        final selected = assets.firstWhere(
          (asset) =>
              (asset['name'] as String?)?.toLowerCase().endsWith('.exe') ??
              false,
          orElse: () => assets[0],
        );
        downloadUrl = selected['browser_download_url'] as String?;
      }
      final releaseNotes = latestRelease['body'] as String?;
      final updateSize = (latestRelease['assets'] as List?)?.isNotEmpty == true
          ? ((latestRelease['assets'][0]['size'] as int?) ?? 0) ~/ (1024 * 1024)
          : null;

      // Compare versions
      if (_isNewerVersion(latestVersion, currentVersion)) {
        return UpdateInfo(
          currentVersion: currentVersion,
          latestVersion: latestVersion ?? currentVersion,
          downloadUrl: downloadUrl ?? '',
          releaseNotes: releaseNotes ?? '',
          isRequired: false,
          updateSize: updateSize,
        );
      }
    } catch (e) {
      print('UpdateService: Error checking for updates: $e');
    }

    return null;
  }

  /// Compare version strings (e.g., "1.0.0" vs "1.0.1")
  static bool _isNewerVersion(String? newVersion, String currentVersion) {
    print(
      'UpdateService: Comparing versions - new: $newVersion, current: $currentVersion',
    );
    if (newVersion == null || newVersion == currentVersion) return false;

    final newParts = newVersion.split('.').map(int.tryParse).toList();
    final currentParts = currentVersion.split('.').map(int.tryParse).toList();
    print(
      'UpdateService: Parsed versions - new: $newParts, current: $currentParts',
    );

    if (newParts.length != 3 || currentParts.length != 3) {
      print('UpdateService: Invalid version format');
      return false;
    }

    for (int i = 0; i < 3; i++) {
      final newPart = newParts[i] ?? 0;
      final currentPart = currentParts[i] ?? 0;

      if (newPart > currentPart) return true;
      if (newPart < currentPart) return false;
    }

    return false;
  }

  /// Get the current installed version
  static Future<String> getCurrentVersion() async {
    return "2.1.0";
  }

  /// Get the current build number
  static Future<String> getCurrentBuild() async {
    return "20260501";
  }

  /// Download and install update
  static Future<bool> downloadAndInstall(String downloadUrl) async {
    try {
      print('UpdateService: Downloading from $downloadUrl');

      // Download installer
      final response = await http.get(Uri.parse(downloadUrl));
      if (response.statusCode != 200) {
        return false;
      }

      // Save to temp directory
      final tempDir = await getTemporaryDirectory();
      final installerPath = '${tempDir.path}\\FLO-Update.exe';
      final file = File(installerPath);
      await file.writeAsBytes(response.bodyBytes);

      // Run installer
      await Process.start(installerPath, ['/SILENT']);

      // Exit current app
      exit(0);

      return true;
    } catch (e) {
      print('UpdateService: Error: $e');
      return false;
    }
  }
}

/// Information about an available update
class UpdateInfo {
  final String currentVersion;
  final String latestVersion;
  final String downloadUrl;
  final String releaseNotes;
  final bool isRequired;
  final int? updateSize;

  UpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.downloadUrl,
    required this.releaseNotes,
    required this.isRequired,
    this.updateSize,
  });

  String get versionDisplay => 'v$latestVersion';
  String get sizeDisplay =>
      updateSize != null ? '${updateSize}MB' : 'Unknown size';
}
