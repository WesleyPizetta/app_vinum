import 'package:essentials/essentials.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/utils/json_utils.dart';
import '../../domain/entity/food_category.dart';
import '../../domain/entity/recommendation_failure_code.dart';
import '../../domain/entity/recommendation_page.dart';
import '../../domain/entity/recommended_wine.dart';
import '../../domain/entity/search_result.dart';
import '../../domain/entity/wine_match.dart';
import '../../domain/repository/recommendation_repository.dart';
import '../api/recommendation_api_service.dart';
import '../model/recommendation_page_model.dart';
import '../model/search_result_model.dart';
import '../model/wine_match_model.dart';

class RecommendationRepositoryImpl implements RecommendationRepository {
  final RecommendationApiService _apiService;

  const RecommendationRepositoryImpl(this._apiService);

  /// Recomendação geral da home: primeira página, sem filtro de comida.
  @override
  Future<Try<List<RecommendedWine>>> getRecommendations({int? limit}) async {
    final result = await getRecommendationsPage(limit: limit);
    return result.fold(
      (failure) => Try.reject<List<RecommendedWine>>(failure),
      (page) => Try.success<List<RecommendedWine>>(page.items),
    );
  }

  @override
  Future<Try<RecommendationPage>> getRecommendationsPage({
    int? limit,
    int offset = 0,
    FoodCategory? food,
  }) async {
    try {
      // O token é injetado pelo AuthHeaderInterceptor. `offset` 0 não é
      // enviado para manter a chamada da home idêntica à anterior.
      final response = await _apiService.getRecommendations(
        limit: limit,
        offset: offset > 0 ? offset : null,
        food: food?.apiValue,
      );
      if (!response.isSuccessful) {
        return Try.reject(_httpFailure(response));
      }

      final model = RecommendationPageModel.tryParse(
        response.body,
        requestedOffset: offset,
      );
      if (model == null) {
        return Try.reject(KnownFailure(
          RecommendationFailureCode.invalidResponse,
          response.bodyString,
          message: 'Resposta de /me/recommendations fora do contrato',
        ));
      }

      return Try.success(model.toEntity());
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[RecommendationRepository] erro ao carregar: $e');
      }
      return Try.reject(UnknownFailure(e));
    }
  }

  @override
  Future<Try<WineMatch>> getWineMatch(String wineId) async {
    try {
      final response = await _apiService.getWineMatch(wineId);
      if (!response.isSuccessful) {
        return Try.reject(_httpFailure(response));
      }

      final model = WineMatchModel.tryParse(
        response.body ?? response.bodyString,
        requestedWineId: wineId,
      );
      if (model == null) {
        return Try.reject(KnownFailure(
          RecommendationFailureCode.invalidResponse,
          response.bodyString,
          message: 'Resposta de /me/wines/{id}/match fora do contrato',
        ));
      }

      return Try.success(model.toEntity());
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[RecommendationRepository] erro no match: $e');
      }
      return Try.reject(UnknownFailure(e));
    }
  }

  @override
  Future<Try<SearchResult>> search({
    required String query,
    int? limit,
    int offset = 0,
  }) async {
    try {
      final response = await _apiService.search(
        query: query,
        limit: limit,
        offset: offset,
      );
      if (!response.isSuccessful) {
        return Try.reject(_httpFailure(response));
      }

      final model = SearchResultModel.tryParse(
        response.body ?? response.bodyString,
        requestedQuery: query,
        requestedOffset: offset,
      );
      if (model == null) {
        return Try.reject(KnownFailure(
          RecommendationFailureCode.invalidResponse,
          response.bodyString,
          message: 'Resposta de /me/search fora do contrato',
        ));
      }

      return Try.success(model.toEntity());
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[RecommendationRepository] erro na busca: $e');
      }
      return Try.reject(UnknownFailure(e));
    }
  }

  /// Traduz o status HTTP para um [KnownFailure] com código de
  /// [RecommendationFailureCode].
  KnownFailure _httpFailure(Response<dynamic> response) {
    final statusCode = response.statusCode;
    final rawError = response.error ?? response.bodyString;
    final backendCode = JsonUtils.readErrorCode(rawError);

    final String code;
    if (statusCode == 409 &&
        (backendCode == null ||
            backendCode == RecommendationFailureCode.onboardingRequired)) {
      code = RecommendationFailureCode.onboardingRequired;
    } else if (statusCode == 401) {
      code = RecommendationFailureCode.unauthorized;
    } else if (statusCode == 404) {
      code = RecommendationFailureCode.notFound;
    } else if (statusCode == 400) {
      code = RecommendationFailureCode.badRequest;
    } else if (statusCode >= 500) {
      code = RecommendationFailureCode.server;
    } else {
      code = RecommendationFailureCode.requestFailed;
    }

    final backendMessage = JsonUtils.readErrorMessage(rawError);
    if (kDebugMode) {
      debugPrint('[RecommendationRepository] HTTP $statusCode '
          '(${backendCode ?? '-'}) -> $code ($backendMessage)');
    }
    return KnownFailure(
      code,
      response.error,
      message: backendMessage ?? 'HTTP $statusCode',
    );
  }
}
