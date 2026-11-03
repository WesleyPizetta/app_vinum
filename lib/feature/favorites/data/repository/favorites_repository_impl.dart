import 'dart:async';

import 'package:essentials/essentials.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/utils/json_utils.dart';
import '../../domain/entity/favorite_failure_code.dart';
import '../../domain/entity/favorite_ids.dart';
import '../../domain/entity/favorite_wines_page.dart';
import '../../domain/repository/favorites_repository.dart';
import '../api/favorite_api_service.dart';
import '../model/favorite_ids_model.dart';
import '../model/favorite_wines_page_model.dart';

/// Implementação com cache em memória dos ids favoritos.
///
/// Concorrência:
/// - cada [setFavorite] recebe um número de sequência por vinho; só a
///   operação mais recente de um vinho confirma/reverte o cache (toques
///   rápidos "favoritar → desfavoritar" não se atropelam);
/// - operações em voo ficam em [_pending] e são reaplicadas sobre o
///   resultado de [loadIds];
/// - [clear] incrementa [_epoch]; respostas de antes do logout são
///   descartadas sem tocar no cache.
class FavoritesRepositoryImpl implements FavoritesRepository {
  final FavoriteApiService _apiService;

  FavoritesRepositoryImpl(this._apiService);

  final StreamController<FavoriteIds> _controller =
      StreamController<FavoriteIds>.broadcast();

  Set<String> _ids = <String>{};
  Set<String> _removed = <String>{};
  bool _loaded = false;
  FavoriteIds _snapshot = FavoriteIds.empty;

  int _epoch = 0;
  final Map<String, int> _sequence = <String, int>{};
  final Map<String, bool> _pending = <String, bool>{};
  Future<Try<FavoriteIds>>? _loading;

  @override
  FavoriteIds get currentFavoriteIds => _snapshot;

  @override
  Stream<FavoriteIds> watchFavoriteIds() => _controller.stream;

  @override
  Future<Try<FavoriteIds>> loadIds() {
    final inFlight = _loading;
    if (inFlight != null) return inFlight;

    late final Future<Try<FavoriteIds>> future;
    future = _fetchIds().whenComplete(() {
      if (identical(_loading, future)) _loading = null;
    });
    _loading = future;
    return future;
  }

  Future<Try<FavoriteIds>> _fetchIds() async {
    final epoch = _epoch;
    try {
      final response = await _apiService.getFavoriteIds();
      if (epoch != _epoch) return Try.success(_snapshot); // logout no meio
      if (!response.isSuccessful) {
        return Try.reject(_httpFailure(response));
      }

      final ids = FavoriteIdsModel.tryParse(
        response.body ?? response.bodyString,
      );
      if (ids == null) {
        return Try.reject(KnownFailure(
          FavoriteFailureCode.invalidResponse,
          response.bodyString,
          message: 'Resposta de /me/favorites/ids fora do contrato',
        ));
      }

      // O servidor ainda não reflete as operações em voo: reaplica.
      final merged = <String>{...ids};
      _pending.forEach((wineId, isFavorite) {
        if (isFavorite) {
          merged.add(wineId);
        } else {
          merged.remove(wineId);
        }
      });
      _ids = merged;
      _removed = <String>{};
      _loaded = true;
      _emit();
      return Try.success(_snapshot);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[FavoritesRepository] erro ao carregar ids: $e');
      }
      return Try.reject(UnknownFailure(e));
    }
  }

  @override
  Future<Try<bool>> setFavorite(String wineId, bool isFavorite) async {
    final id = wineId.trim();
    if (id.isEmpty) {
      return Try.reject(KnownFailure(
        FavoriteFailureCode.badRequest,
        null,
        message: 'wine_id vazio',
      ));
    }

    final previous = _snapshot.isFavorite(id);
    if (previous == isFavorite) return Try.success(isFavorite);

    final epoch = _epoch;
    final sequence = (_sequence[id] ?? 0) + 1;
    _sequence[id] = sequence;
    _pending[id] = isFavorite;

    // Otimista.
    _apply(id, isFavorite);
    _emit();

    Try<bool> result;
    try {
      final response = isFavorite
          ? await _apiService.addFavorite(id)
          : await _apiService.removeFavorite(id);
      if (!response.isSuccessful) {
        result = Try.reject(_httpFailure(response));
      } else {
        final confirmed = FavoriteStatusModel.readIsFavorite(
              response.body ?? response.bodyString,
            ) ??
            isFavorite;
        result = Try.success(confirmed);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[FavoritesRepository] erro ao alterar $id: $e');
      }
      result = Try.reject(UnknownFailure(e));
    }

    // Logout durante a requisição: o cache já é de outra sessão.
    if (epoch != _epoch) return result;
    // Uma operação mais nova do mesmo vinho é dona do estado.
    if (_sequence[id] != sequence) return result;

    _pending.remove(id);
    final failure = result.fold<Failure?>((f) => f, (_) => null);
    if (failure != null) {
      _restore(id, previous);
      _emit();
    } else {
      final confirmed = result.getOrElse(() => isFavorite);
      if (confirmed != isFavorite) {
        _apply(id, confirmed);
        _emit();
      }
    }
    return result;
  }

  @override
  Future<Try<FavoriteWinesPage>> getFavoritesPage({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _apiService.getFavorites(
        limit: limit,
        offset: offset,
      );
      if (!response.isSuccessful) {
        return Try.reject(_httpFailure(response));
      }

      final model = FavoriteWinesPageModel.tryParse(
        response.body ?? response.bodyString,
        requestedOffset: offset,
      );
      if (model == null) {
        return Try.reject(KnownFailure(
          FavoriteFailureCode.invalidResponse,
          response.bodyString,
          message: 'Resposta de /me/favorites fora do contrato',
        ));
      }
      return Try.success(model.toEntity());
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[FavoritesRepository] erro ao listar favoritos: $e');
      }
      return Try.reject(UnknownFailure(e));
    }
  }

  @override
  void clear() {
    _epoch++;
    _ids = <String>{};
    _removed = <String>{};
    _loaded = false;
    _pending.clear();
    _sequence.clear();
    _loading = null;
    _emit();
  }

  void _apply(String wineId, bool isFavorite) {
    if (isFavorite) {
      _ids.add(wineId);
      _removed.remove(wineId);
    } else {
      _ids.remove(wineId);
      // Depois de carregado, "fora de _ids" já significa "não favorito".
      if (!_loaded) _removed.add(wineId);
    }
  }

  /// Volta [wineId] ao estado anterior (`null` = desconhecido).
  void _restore(String wineId, bool? previous) {
    if (previous == null) {
      _ids.remove(wineId);
      _removed.remove(wineId);
    } else {
      _apply(wineId, previous);
    }
  }

  void _emit() {
    _snapshot = FavoriteIds(
      ids: Set<String>.unmodifiable(_ids),
      removed: Set<String>.unmodifiable(_removed),
      isLoaded: _loaded,
    );
    if (!_controller.isClosed) _controller.add(_snapshot);
  }

  /// Traduz o status HTTP para um [KnownFailure] com código de
  /// [FavoriteFailureCode].
  KnownFailure _httpFailure(Response<dynamic> response) {
    final statusCode = response.statusCode;
    final rawError = response.error ?? response.bodyString;

    final String code;
    if (statusCode == 401) {
      code = FavoriteFailureCode.unauthorized;
    } else if (statusCode == 404) {
      code = FavoriteFailureCode.notFound;
    } else if (statusCode == 400) {
      code = FavoriteFailureCode.badRequest;
    } else if (statusCode >= 500) {
      code = FavoriteFailureCode.server;
    } else {
      code = FavoriteFailureCode.requestFailed;
    }

    final backendMessage = JsonUtils.readErrorMessage(rawError);
    if (kDebugMode) {
      debugPrint('[FavoritesRepository] HTTP $statusCode -> $code '
          '($backendMessage)');
    }
    return KnownFailure(
      code,
      response.error,
      message: backendMessage ?? 'HTTP $statusCode',
    );
  }
}
