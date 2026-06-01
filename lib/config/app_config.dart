import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

AppConfig get appConfig => AppConfig._instance ??= AppConfig();

class AppConfig {
  static AppConfig? _instance;

  /// null = 跟随系统，否则为 Brightness.light / Brightness.dark 的 toString()
  String? brightness;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('app_config');
      if (jsonString == null) return;
      final data = json.decode(jsonString) as Map<String, dynamic>;
      brightness = data['brightness'] as String?;
    } catch (e) {
      debugPrint('AppConfig init error: $e');
    }
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'app_config',
      json.encode({'brightness': brightness}),
    );
  }
}
