import 'package:essentials/essentials.dart';
import 'package:flutter/material.dart';

import '../repository/settings_repository.dart';

class GetThemeMode implements UnitUseCase<ThemeMode> {
  final SettingsRepository _repository;

  GetThemeMode(this._repository);

  @override
  Future<Try<ThemeMode>> call() => _repository.getThemeMode();
}
