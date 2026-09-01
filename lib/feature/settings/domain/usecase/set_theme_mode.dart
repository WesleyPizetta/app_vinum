import 'package:essentials/essentials.dart';
import 'package:flutter/material.dart';

import '../repository/settings_repository.dart';

class SetThemeMode implements UseCase<void, ThemeMode> {
  final SettingsRepository _repository;

  SetThemeMode(this._repository);

  @override
  Future<Try<void>> call(ThemeMode params) => _repository.setThemeMode(params);
}
