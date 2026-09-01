import 'package:essentials/essentials.dart';
import 'package:flutter/material.dart';

import '../../domain/repository/settings_repository.dart';
import '../datasource/settings_datasource.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsDatasource _datasource;

  const SettingsRepositoryImpl(this._datasource);

  @override
  Future<Try<ThemeMode>> getThemeMode() async {
    try {
      final mode = await _datasource.getThemeMode();
      return Try.success(mode);
    } catch (e) {
      return Try.reject(UnknownFailure(e));
    }
  }

  @override
  Future<Try<void>> setThemeMode(ThemeMode themeMode) async {
    try {
      await _datasource.setThemeMode(themeMode);
      return Try.success(null);
    } catch (e) {
      return Try.reject(UnknownFailure(e));
    }
  }
}
