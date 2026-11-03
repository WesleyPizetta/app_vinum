import 'package:essentials/essentials.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/utils/json_utils.dart';
import '../../domain/entity/nickname_availability.dart';
import '../../domain/entity/nickname_failure_code.dart';
import '../../domain/repository/nickname_repository.dart';
import '../api/profile_api_service.dart';
import '../model/nickname_availability_model.dart';

/// O token (quando houver) é injetado pelo `AuthHeaderInterceptor`.
class NicknameRepositoryImpl implements NicknameRepository {
  final ProfileApiService _apiService;

  NicknameRepositoryImpl(this._apiService);

  @override
  Future<Try<NicknameAvailability>> checkAvailability(String nickname) async {
    final Response<dynamic> response;
    try {
      response = await _apiService.checkNickname(nickname);
    } catch (e) {
      return Try.reject(_networkFailure(e));
    }

    if (!response.isSuccessful) {
      final failure = _httpFailure(response);
      // Regra violada (ex.: 422 NICKNAME_INVALID_FORMAT): é uma resposta
      // válida de "indisponível", não um erro de rede.
      if (NicknameFailureCode.isRuleViolation(failure.code)) {
        return Try.success(NicknameAvailability(
          nickname: nickname,
          available: false,
          code: failure.code,
        ));
      }
      return Try.reject(failure);
    }

    final availability = NicknameAvailabilityModel.tryParse(
      response.body ?? response.bodyString,
      requestedNickname: nickname,
    );
    if (availability == null) {
      return Try.reject(KnownFailure(
        NicknameFailureCode.invalidResponse,
        response.bodyString,
        message: 'Resposta de /nicknames/check fora do contrato',
      ));
    }
    if (!availability.available && availability.code == null) {
      return Try.success(NicknameAvailability(
        nickname: availability.nickname,
        available: false,
        code: NicknameFailureCode.taken,
      ));
    }
    return Try.success(availability);
  }

  @override
  Future<Try<String>> setMyNickname(String nickname) async {
    final Response<dynamic> response;
    try {
      response = await _apiService.setMyNickname(
        <String, dynamic>{'nickname': nickname},
      );
    } catch (e) {
      return Try.reject(_networkFailure(e));
    }

    if (!response.isSuccessful) {
      return Try.reject(_httpFailure(response));
    }

    // Sem `nickname` no corpo, vale o que foi enviado (já normalizado).
    final saved =
        NicknameModel.readNickname(response.body ?? response.bodyString) ??
            nickname;
    return Try.success(saved);
  }

  KnownFailure _networkFailure(Object error) {
    if (kDebugMode) {
      debugPrint('[NicknameRepository] erro de transporte: $error');
    }
    return KnownFailure(
      NicknameFailureCode.network,
      error,
      message: error.toString(),
    );
  }

  /// Traduz o status HTTP para um [KnownFailure]. 409/422 usam o `code` do
  /// corpo (`NICKNAME_*`) quando presente.
  KnownFailure _httpFailure(Response<dynamic> response) {
    final statusCode = response.statusCode;
    final rawError = response.error ?? response.bodyString;
    final backendCode = JsonUtils.readErrorCode(rawError);

    final String code;
    if (NicknameFailureCode.isRuleViolation(backendCode)) {
      code = backendCode!;
    } else if (statusCode == 409) {
      code = NicknameFailureCode.taken;
    } else if (statusCode == 422) {
      code = NicknameFailureCode.invalidFormat;
    } else if (statusCode == 401) {
      code = NicknameFailureCode.unauthorized;
    } else if (statusCode == 400) {
      code = NicknameFailureCode.badRequest;
    } else if (statusCode >= 500) {
      code = NicknameFailureCode.server;
    } else {
      code = NicknameFailureCode.requestFailed;
    }

    final backendMessage = JsonUtils.readErrorMessage(rawError);
    if (kDebugMode) {
      debugPrint('[NicknameRepository] HTTP $statusCode -> $code '
          '($backendMessage)');
    }
    return KnownFailure(
      code,
      response.error,
      message: backendMessage ?? 'HTTP $statusCode',
    );
  }
}
