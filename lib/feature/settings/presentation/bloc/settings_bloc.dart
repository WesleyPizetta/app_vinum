import 'package:essentials/essentials.dart';

import '../../domain/usecase/get_theme_mode.dart';
import '../../domain/usecase/set_theme_mode.dart';
import 'settings_event.dart';
import 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final GetThemeMode _getThemeMode;
  final SetThemeMode _setThemeMode;

  SettingsBloc(
    this._getThemeMode,
    this._setThemeMode,
  ) : super(const SettingsInitial()) {
    on<SettingsStarted>(_onStarted);
    on<SettingsThemeChanged>(_onThemeChanged);
  }

  Future<void> _onStarted(
    SettingsStarted event,
    Emitter<SettingsState> emit,
  ) async {
    final result = await _getThemeMode();
    result.fold(
      (failure) => emit(SettingsLoaded(themeMode: state.themeMode)),
      (themeMode) => emit(SettingsLoaded(themeMode: themeMode)),
    );
  }

  Future<void> _onThemeChanged(
    SettingsThemeChanged event,
    Emitter<SettingsState> emit,
  ) async {
    emit(SettingsLoaded(themeMode: event.themeMode));
    await _setThemeMode(event.themeMode);
  }
}
