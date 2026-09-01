import 'package:flutter/material.dart';

sealed class SettingsState {
  final ThemeMode themeMode;

  const SettingsState({required this.themeMode});
}

class SettingsInitial extends SettingsState {
  const SettingsInitial({super.themeMode = ThemeMode.system});
}

class SettingsLoaded extends SettingsState {
  const SettingsLoaded({required super.themeMode});
}
