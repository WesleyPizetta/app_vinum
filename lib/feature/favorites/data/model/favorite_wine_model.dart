import '../../../../core/utils/json_utils.dart';
import '../../../wine/data/model/wine_model.dart';
import '../../domain/entity/favorite_wine.dart';

/// Item de `favorites` em `GET /v1/me/favorites`: os campos de
/// `GET /v1/wines/{id}` + `favorited_at` (RFC3339).
class FavoriteWineModel {
  final WineModel wine;
  final DateTime? favoritedAt;

  const FavoriteWineModel({required this.wine, this.favoritedAt});

  /// Retorna `null` se o vinho for inválido (sem `wine_id` ou `name`).
  static FavoriteWineModel? tryParse(dynamic json) {
    final map = JsonUtils.asMap(json);
    if (map == null) return null;
    final wine = WineModel.tryParse(map);
    if (wine == null) return null;

    final rawDate = JsonUtils.readString(map['favorited_at']);
    return FavoriteWineModel(
      wine: wine,
      favoritedAt: rawDate == null ? null : DateTime.tryParse(rawDate),
    );
  }

  FavoriteWine toEntity() => FavoriteWine(
        wine: wine.toEntity(),
        favoritedAt: favoritedAt,
      );
}
