import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class FileUtils {
  /// Guarda bytes localmente y retorna la ruta absoluta.
  static Future<String> saveBytesLocally({
    required List<int> bytes,
    required String fileName,
    String? subdirectory,
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    final targetDir = subdirectory != null
        ? Directory('${dir.path}/$subdirectory')
        : dir;
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }
    final file = File('${targetDir.path}/$fileName');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  /// Intenta obtener una imagen desde el portapapeles.
  /// Retorna bytes y metadatos si existe.
  static Future<ClipboardData?> getImageFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    return data;
  }

  static String extensionFromMime(String mime) {
    switch (mime) {
      case 'image/png':
        return '.png';
      case 'image/jpeg':
      case 'image/jpg':
        return '.jpg';
      case 'image/gif':
        return '.gif';
      case 'image/webp':
        return '.webp';
      case 'video/mp4':
        return '.mp4';
      case 'video/webm':
        return '.webm';
      case 'audio/mp4':
      case 'audio/m4a':
        return '.m4a';
      case 'audio/mpeg':
      case 'audio/mp3':
        return '.mp3';
      case 'audio/wav':
        return '.wav';
      case 'audio/ogg':
        return '.ogg';
      default:
        return '.bin';
    }
  }

  static String detectMediaType(String path) {
    final ext = path.split('.').last.toLowerCase();
    if (['png', 'jpg', 'jpeg', 'gif', 'webp'].contains(ext)) {
      return 'image';
    }
    if (['mp4', 'webm', 'mov'].contains(ext)) {
      return 'video';
    }
    if (['m4a', 'mp3', 'wav', 'ogg', 'aac'].contains(ext)) {
      return 'audio';
    }
    return 'unknown';
  }
}
