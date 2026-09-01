import 'package:essentials/essentials.dart';
import 'package:flutter/material.dart';

abstract class SettingsRepository {
  Future<Try<ThemeMode>> getThemeMode();
  Future<Try<void>> setThemeMode(ThemeMode themeMode);
}
