import 'dart:io';
import 'package:crypto/crypto.dart';

Future<String> calculateFileHash(File file) async {
  final stream = file.openRead();
  final hash = await sha256.bind(stream).first;
  return hash.toString();
}
