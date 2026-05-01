// import 'package:package_info_plus/package_info_plus.dart';

/// Service for managing version information and checking compatibility
class VersionService {
  static final VersionService instance = VersionService._();
  VersionService._();

  // PackageInfo? _packageInfo;

  /// Expected backend version format: vX.Y.Z-YYYYMMDD.HHMM
  static const String expectedBackendVersion = 'v1.0.0-20251120.2330';

  /// Initialize the service and load package info
  Future<void> init() async {
    // _packageInfo = await PackageInfo.fromPlatform();
  }

  /// Get full version string: "1.0.0+20251120"
  String get fullVersion => '2.1.0+20260501';

  /// Get version number: "1.0.0"
  String get version => '2.1.0';

  /// Get build number: "20251120"
  String get buildNumber => '20260501';

  /// Get formatted version with date: "v1.0.0 (2025-11-20)"
  String get formattedVersion {
    final ver = version;
    final build = buildNumber;

    if (build.length == 8) {
      // Parse YYYYMMDD format
      final year = build.substring(0, 4);
      final month = build.substring(4, 6);
      final day = build.substring(6, 8);
      return 'v$ver ($year-$month-$day)';
    }

    return 'v$ver+$build';
  }

  /// Get app name
  String get appName => 'FlowSpace';

  /// Get package name
  String get packageName => 'com.vyrevault.flo';

  /// Check if backend version is compatible
  /// Returns true if major versions match
  bool isBackendCompatible(String backendVersion) {
    try {
      // Extract major version from backend (e.g., "v1.0.0-20251120.2330" -> "1")
      final backendMajor = int.parse(
        backendVersion.split('.')[0].replaceAll('v', ''),
      );

      // Extract major version from client (e.g., "1.0.0" -> "1")
      final clientMajor = int.parse(version.split('.')[0]);

      return backendMajor == clientMajor;
    } catch (e) {
      print('VersionService: Error checking compatibility: $e');
      return false;
    }
  }

  /// Get version info for display
  Map<String, String> getVersionInfo() {
    return {
      'App Name': appName,
      'Version': formattedVersion,
      'Build': buildNumber,
      'Package': packageName,
      'Backend': expectedBackendVersion,
    };
  }

  /// Get copyright string
  String get copyright => '© ${DateTime.now().year} VyreVault Studios';
}
