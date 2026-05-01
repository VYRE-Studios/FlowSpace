import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class FloPaths {
  static Future<Directory> appDataRoot() async {
    final dir = await getApplicationSupportDirectory();
    final root = Directory(p.join(dir.path, 'VyreVault', 'Flo'));
    if (!await root.exists()) await root.create(recursive: true);
    return root;
  }

  static Future<Directory> projectsRoot() async {
    final root = await appDataRoot();
    final d = Directory(p.join(root.path, 'projects'));
    if (!await d.exists()) await d.create(recursive: true);
    return d;
  }

  static Future<Directory> vaultRoot() async {
    final root = await appDataRoot();
    final d = Directory(p.join(root.path, 'vault'));
    if (!await d.exists()) await d.create(recursive: true);
    return d;
  }

  static Future<Directory> logsRoot() async {
    final root = await appDataRoot();
    final d = Directory(p.join(root.path, 'logs'));
    if (!await d.exists()) await d.create(recursive: true);
    return d;
  }

  static Future<File> buildInfoFile() async {
    final root = await appDataRoot();
    final f = File(p.join(root.path, 'build_info.json'));
    if (!await f.exists()) await f.writeAsString('{}');
    return f;
  }
}

