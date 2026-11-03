import 'package:essentials/essentials.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/utils/json_utils.dart';
import '../../domain/entity/cellar_failure_code.dart';
import '../../domain/entity/cellar_reviews_page.dart';
import '../../domain/repository/cellar_repository.dart';
import '../api/cellar_api_service.dart';
import '../model/cellar_reviews_page_model.dart';

class CellarRepositoryImpl implements CellarRepository {
  final CellarApiService _apiService;

  CellarRepositoryImpl(this._apiService);

  @override
  Future<Try<CellarReviewsPage>> getMyReviews({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _apiService.getMyReviews(
        limit: limit,
        offset: offset,
      );
      if (!response.isSuccessful) {
        return Try.reject(_httpFailure(response));
      }

      final model = CellarReviewsPageModel.tryParse(
        response.body ?? response.bodyString,
        requestedOffset: offset,
      );
      if (model == null) {
        return Try.reject(KnownFailure(
          CellarFailureCode.invalidResponse,
          response.bodyString,
          message: 'Resposta de /me/reviews fora do contrato',
        ));
      }
      return Try.success(model.toEntity());
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CellarRepository] erro ao listar avaliações: $e');
      }
      return Try.reject(UnknownFailure(e));
    }
  }

  /// Traduz o status HTTP para um [KnownFailure] com código de
  /// [CellarFailureCode].
  KnownFailure _httpFailure(Response<dynamic> response) {
    final statusCode = response.statusCode;
    final rawError = response.error ?? response.bodyString;

    final String code;
    if (statusCode == 401) {
      code = CellarFailureCode.unauthorized;
    } else if (statusCode == 400) {
      code = CellarFailureCode.badRequest;
    } else if (statusCode >= 500) {
      code = CellarFailureCode.server;
    } else {
      code = CellarFailureCode.requestFailed;
    }

    final backendMessage = JsonUtils.readErrorMessage(rawError);
    if (kDebugMode) {
      debugPrint('[CellarRepository] HTTP $statusCode -> $code '
          '($backendMessage)');
    }
    return KnownFailure(
      code,
      response.error,
      message: backendMessage ?? 'HTTP $statusCode',
    );
  }
}
