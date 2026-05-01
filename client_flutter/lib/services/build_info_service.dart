import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class BuildInfoService {
  static String version = 'Unknown';
  static String build = 'Unknown';

  static Future<void> load() async {
    try {
      final txt = await rootBundle.loadString('assets/build_info.json');
      final map = jsonDecode(txt) as Map<String, dynamic>;
      version = map['version']?.toString() ?? version;
      build = map['build']?.toString() ?? build;
    } catch (_) {
      // ignore: no-op
    }
  }
}
