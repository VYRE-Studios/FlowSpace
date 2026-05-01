// lib/assets/checksum.dart

import 'dart:io';
import 'package:crypto/crypto.dart';

Future<String> fileChecksum(File file) async {
  final bytes = await file.readAsBytes();
  return sha1.convert(bytes).toString();
}
