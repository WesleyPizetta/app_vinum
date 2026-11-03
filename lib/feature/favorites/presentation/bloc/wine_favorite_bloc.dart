import 'dart:async';

import 'package:essentials/essentials.dart';

import '../../../auth/domain/usecase/logout.dart';
import '../../domain/entity/favorite_failure_code.dart';
import '../../domain/entity/favorite_ids.dart';
import '../../domain/usecase/load_favorite_ids.dart';
import '../../domain/usecase/set_favorite.dart';
import '../../domain/usecase/watch_favorite_ids.dart';

// ── Eventos ──

sealed class WineFavoriteEvent {}

/// Define o vinho do botão e resolve o estado inicial pelo cache (carrega os
/// ids se ainda não estiverem em memória).
class WineFavoriteStarted extends WineFavoriteEvent {
  final String wineId;

  WineFavoriteStarted(this.wineId);
}

class WineFavoriteToggled extends WineFavoriteEvent {}

/// Interno: o cache de favoritos mudou.
class WineFavoriteIdsChanged extends WineFavoriteEvent {
  final FavoriteIds ids;

  WineFavoriteIdsChanged(this.ids);
}

// ── Estado ──

class WineFavoriteState {
  final String? wineId;

  /// `null` enquanto o estado ainda não é conhecido (botão desabilitado).
  final bool? isFavorite;

  /// Chave i18n de falha ao alterar (SnackBar). Transitório: não é copiado
  /// por [copyWith].
  final String? errorMessage;

  /// 401: logout já executado, a tela volta ao login.
  final bool sessionExpired;

  const WineFavoriteState({
    this.wineId,
    this.isFavorite,
    this.errorMessage,
    this.sessionExpired = false,
  });

  WineFavoriteState copyWith({
    String? wineId,
    bool? isFavorite,
    String? errorMessage,
    bool? sessionExpired,
  }) {
    return WineFavoriteState(
      wineId: wineId ?? this.wineId,
      isFavorite: isFavorite ?? this.isFavorite,
      errorMessage: errorMessage,
      sessionExpired: sessionExpired ?? this.sessionExpired,
    );
  }
}

// ── Bloc ──

/// Estado de favorito de um único vinho (botão do detalhe), sincronizado com
/// o cache compartilhado.
class WineFavoriteBloc extends Bloc<WineFavoriteEvent, WineFavoriteState> {
  final LoadFavoriteIds _loadFavoriteIds;
  final SetFavorite _setFavorite;
  final WatchFavoriteIds _watchFavoriteIds;
  final Logout _logout;

  late final StreamSubscription<FavoriteIds> _idsSubscription;

  WineFavoriteBloc(
    this._loadFavoriteIds,
    this._setFavorite,
    this._watchFavoriteIds,
    this._logout,
  ) : super(const WineFavoriteState()) {
    on<WineFavoriteStarted>(_onStarted);
    on<WineFavoriteToggled>(_onToggled);
    on<WineFavoriteIdsChanged>(_onIdsChanged);

    _idsSubscription = _watchFavoriteIds().listen((ids) {
      if (!isClosed) add(WineFavoriteIdsChanged(ids));
    });
  }

  @override
  Future<void> close() async {
    await _idsSubscription.cancel();
    return super.close();
  }

  Future<void> _onStarted(
    WineFavoriteStarted event,
    Emitter<WineFavoriteState> emit,
  ) async {
    final wineId = event.wineId;
    final known = _watchFavoriteIds.current.isFavorite(wineId);
    emit(WineFavoriteState(wineId: wineId, isFavorite: known));
    if (known != null) return;

    await _loadFavoriteIds();
    if (state.wineId != wineId || state.isFavorite != null) return;
    // Sem a lista (falha de rede), assume "não favorito" e deixa tocar.
    emit(state.copyWith(
      isFavorite: _watchFavoriteIds.current.isFavorite(wineId) ?? false,
    ));
  }

  Future<void> _onToggled(
    WineFavoriteToggled event,
    Emitter<WineFavoriteState> emit,
  ) async {
    final wineId = state.wineId;
    final current = state.isFavorite;
    if (wineId == null || current == null || state.sessionExpired) return;

    final target = !current;
    emit(state.copyWith(isFavorite: target));

    final result = await _setFavorite(
      SetFavoriteParams(wineId: wineId, isFavorite: target),
    );
    final failure = result.fold<Failure?>((f) => f, (_) => null);
    if (failure == null) return;

    if (failure is KnownFailure &&
        failure.code == FavoriteFailureCode.unauthorized) {
      await _logout();
      emit(state.copyWith(sessionExpired: true));
      return;
    }

    emit(state.copyWith(
      isFavorite: _watchFavoriteIds.current.isFavorite(wineId) ?? current,
      errorMessage: 'favorite_toggle_error',
    ));
  }

  void _onIdsChanged(
    WineFavoriteIdsChanged event,
    Emitter<WineFavoriteState> emit,
  ) {
    final wineId = state.wineId;
    if (wineId == null) return;
    final value = event.ids.isFavorite(wineId);
    if (value != null && value != state.isFavorite) {
      emit(state.copyWith(isFavorite: value));
    }
  }
}
