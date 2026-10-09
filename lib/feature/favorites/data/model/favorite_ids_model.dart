import '../../../../core/utils/json_utils.dart';

/// Corpo de `GET /v1/me/favorites/ids`: `{"wine_ids": [100003, 108705]}`.
class FavoriteIdsModel {
  FavoriteIdsModel._();

  /// Ids como `String` (mesmo formato de `Wine.id`/`RecommendedWine.id`).
  /// Itens inválidos são descartados. Retorna `null` se o corpo não seguir o
  /// contrato (não é objeto ou `wine_ids` não é lista).
  static Set<String>? tryParse(dynamic body) {
    final map = JsonUtils.asMap(body);
    if (map == null) return null;
    final rawList = JsonUtils.asList(map['wine_ids']);
    if (rawList == null) return null;
    return rawList.map(readWineId).whereType<String>().toSet();
  }

  /// `wine_id` é int no contrato, mas aceita String numérica/UUID.
  static String? readWineId(dynamic raw) =>
      JsonUtils.readInt(raw)?.toString() ?? JsonUtils.readString(raw);
}

/// Corpo de `PUT`/`DELETE /v1/me/favorites/{wine_id}`:
/// `{"wine_id": 100003, "is_favorite": true}`.
class FavoriteStatusModel {
  FavoriteStatusModel._();

  /// `is_favorite` do corpo, ou `null` se ausente/inválido.
  static bool? readIsFavorite(dynamic body) =>
      JsonUtils.readBool(JsonUtils.asMap(body)?['is_favorite']);
}
