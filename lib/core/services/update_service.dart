import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UpdateInfo {
  final String version;
  final String url;
  final String? changelog;

  const UpdateInfo({
    required this.version,
    required this.url,
    this.changelog,
  });
}

class UpdateService {
  static const String _repo = 'ferreirahector731-gif/Norm';
  static const String _apiUrl = 'https://api.github.com/repos/$_repo/releases/latest';
  static const String _prefKey = 'autoUpdateEnabled';
  static const String _skippedKey = 'skippedVersion';

  static Future<bool> isAutoUpdateEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKey) ?? true;
  }

  static Future<void> setAutoUpdateEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, value);
  }

  static Future<void> markSkipped(String version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_skippedKey, version);
  }

  static Future<String> getSkippedVersion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_skippedKey) ?? '';
  }

  static Future<String?> getCurrentVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return info.version;
    } catch (e) {
      debugPrint('Error obteniendo versión actual: $e');
      return null;
    }
  }

  static Future<UpdateInfo?> checkForUpdate() async {
    try {
      final response = await http
          .get(Uri.parse(_apiUrl), headers: {'Accept': 'application/vnd.github.v3+json'})
          .timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) {
        debugPrint('GitHub API respondió ${response.statusCode}');
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final tagName = data['tag_name'] as String? ?? '';
      final version = tagName.startsWith('v') ? tagName.substring(1) : tagName;
      final htmlUrl = data['html_url'] as String? ?? '';
      final body = data['body'] as String?;

      return UpdateInfo(version: version, url: htmlUrl, changelog: body);
    } catch (e) {
      debugPrint('Error checking update: $e');
      return null;
    }
  }

  static Future<bool> hasUpdate(String currentVersion, String remoteVersion) {
    final currentParts = currentVersion.split('.').map(int.tryParse).toList();
    final remoteParts = remoteVersion.split('.').map(int.tryParse).toList();

    if (currentParts.length != 3 || remoteParts.length != 3) return Future.value(false);

    for (int i = 0; i < 3; i++) {
      final c = currentParts[i] ?? 0;
      final r = remoteParts[i] ?? 0;
      if (r > c) return Future.value(true);
      if (r < c) return Future.value(false);
    }
    return Future.value(false);
  }
}
