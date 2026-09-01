import 'package:flutter/material.dart';

sealed class SettingsEvent {}

class SettingsStarted extends SettingsEvent {}

class SettingsThemeChanged extends SettingsEvent {
  final ThemeMode themeMode;

  SettingsThemeChanged(this.themeMode);
}
