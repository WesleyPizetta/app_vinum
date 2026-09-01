import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'settings_datasource.dart';

class SettingsLocalDatasource implements SettingsDatasource {
  static const String _themeKey = 'app_theme_mode';
  SharedPreferences? _prefs;

  SettingsLocalDatasource({SharedPreferences? prefs}) : _prefs = prefs;

  Future<SharedPreferences> _getPrefs() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  @override
  Future<ThemeMode> getThemeMode() async {
    final prefs = await _getPrefs();
    final savedMode = prefs.getString(_themeKey);
    return switch (savedMode) {
      'system' => ThemeMode.system,
      'dark' => ThemeMode.dark,
      'light' => ThemeMode.light,
      _ => ThemeMode.system,
    };
  }

  @override
  Future<void> setThemeMode(ThemeMode themeMode) async {
    final prefs = await _getPrefs();
    final value = switch (themeMode) {
      ThemeMode.system => 'system',
      ThemeMode.dark => 'dark',
      ThemeMode.light => 'light',
    };
    await prefs.setString(_themeKey, value);
  }
}
