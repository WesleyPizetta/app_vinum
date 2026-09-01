import 'package:flutter/material.dart';

abstract class SettingsDatasource {
  Future<ThemeMode> getThemeMode();
  Future<void> setThemeMode(ThemeMode themeMode);
}
