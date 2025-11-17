import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for checking and managing application updates
class UpdateService {
  static const String _updateCheckUrl = 'https://api.flo.app/updates/check';
  static const String _lastCheckKey = 'last_update_check';
  static const Duration _updateCheckInterval = Duration(hours: 24);

  /// Check if an update is available
  static Future<UpdateInfo?> checkForUpdates({bool force = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final buildNumber = packageInfo.buildNumber;

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

      // Make API call to check for updates
      final response = await http.get(
        Uri.parse('$_updateCheckUrl?version=$currentVersion&build=$buildNumber&platform=windows'),
        headers: {'User-Agent': 'FLO/$currentVersion'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        
        // Update last check time
        await prefs.setString(_lastCheckKey, DateTime.now().toIso8601String());

        final latestVersion = data['version'] as String?;
        final latestBuild = data['build'] as String?;
        final downloadUrl = data['download_url'] as String?;
        final releaseNotes = data['release_notes'] as String?;
        final isRequired = data['required'] as bool? ?? false;
        final updateSize = data['size_mb'] as int?;

        // Compare versions
        if (_isNewerVersion(latestVersion, currentVersion)) {
          return UpdateInfo(
            currentVersion: currentVersion,
            latestVersion: latestVersion ?? currentVersion,
            downloadUrl: downloadUrl ?? '',
            releaseNotes: releaseNotes ?? '',
            isRequired: isRequired,
            updateSize: updateSize,
          );
        }
      }
    } catch (e) {
      print('UpdateService: Error checking for updates: $e');
    }

    return null;
  }

  /// Compare version strings (e.g., "1.0.0" vs "1.0.1")
  static bool _isNewerVersion(String? newVersion, String currentVersion) {
    if (newVersion == null || newVersion == currentVersion) return false;

    final newParts = newVersion.split('.').map(int.tryParse).toList();
    final currentParts = currentVersion.split('.').map(int.tryParse).toList();

    if (newParts.length != 3 || currentParts.length != 3) return false;

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
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  /// Get the current build number
  static Future<String> getCurrentBuild() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.buildNumber;
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
  String get sizeDisplay => updateSize != null ? '${updateSize}MB' : 'Unknown size';
}

