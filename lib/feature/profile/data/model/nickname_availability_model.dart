import '../../../../core/utils/json_utils.dart';
import '../../domain/entity/nickname_availability.dart';

/// Corpo de `GET /v1/nicknames/check`:
/// `{"nickname": "wes_pizetta", "available": true}` ou
/// `{"nickname": "...", "available": false, "code": "NICKNAME_TAKEN"}`.
class NicknameAvailabilityModel {
  NicknameAvailabilityModel._();

  /// Retorna `null` se o corpo não seguir o contrato (não é objeto ou
  /// `available` ausente/inválido). Sem `nickname` no corpo, usa
  /// [requestedNickname].
  static NicknameAvailability? tryParse(
    dynamic body, {
    String? requestedNickname,
  }) {
    final map = JsonUtils.asMap(body);
    if (map == null) return null;
    final available = JsonUtils.readBool(map['available']);
    if (available == null) return null;
    final nickname =
        JsonUtils.readString(map['nickname']) ?? requestedNickname ?? '';
    return NicknameAvailability(
      nickname: nickname,
      available: available,
      code: available ? null : JsonUtils.readString(map['code']),
    );
  }
}

/// Corpo de `PUT /v1/me/nickname`: `{"nickname": "wes_pizetta"}`.
class NicknameModel {
  NicknameModel._();

  /// `nickname` do corpo, ou `null` se ausente/vazio.
  static String? readNickname(dynamic body) =>
      JsonUtils.readString(JsonUtils.asMap(body)?['nickname']);
}
