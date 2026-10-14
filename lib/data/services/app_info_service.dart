import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:yaml/yaml.dart';

class AppInfo {
  const AppInfo({
    required this.version,
    required this.buildNumber,
    required this.packageName,
    required this.appName,
    required this.description,
  });

  final String version;
  final String buildNumber;
  final String packageName;
  final String appName;
  final String description;

  String get versionFull => '$version+$buildNumber';
}

class AppInfoService {
  AppInfoService._();
  static final AppInfoService instance = AppInfoService._();

  AppInfo? _cached;
  AppInfo? get cached => _cached;

  Future<AppInfo> load() async {
    if (_cached != null) return _cached!;

    final pkg = await PackageInfo.fromPlatform();

    String description = 'Скидочные карты';
    try {
      final yamlString = await rootBundle.loadString('pubspec.yaml');
      final doc = loadYaml(yamlString);
      if (doc is Map && doc['description'] is String) {
        description = doc['description'] as String;
      }
    } catch (_) {
      // если ассет не подключён — используем дефолт
    }

    _cached = AppInfo(
      version: pkg.version,
      buildNumber: pkg.buildNumber,
      packageName: pkg.packageName,
      appName: pkg.appName,
      description: description,
    );
    return _cached!;
  }
}
