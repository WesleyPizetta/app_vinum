import '../../../../core/utils/json_utils.dart';
import '../../domain/entity/recommended_wine.dart';
import 'wine_match_reason_model.dart';

/// Item de `recommendations` em `GET /v1/me/recommendations` (também usado
/// pelos `wines` de `GET /v1/me/search`).
class RecommendedWineModel {
  final String wineId;
  final String name;
  final String? type;
  final String? body;
  final String? acidity;
  final double? abv;
  final String? country;
  final String? region;
  final String? winery;
  final List<String> grapes;
  final List<String> harmonize;
  final int matchPercent;
  final double? avgRating;
  final int ratingCount;

  /// `is_favorite` da API (ausente -> `false`).
  final bool isFavorite;

  /// `reasons` da API (positivos primeiro); ausente/inválido -> vazio.
  final List<WineMatchReasonModel> reasons;

  const RecommendedWineModel({
    required this.wineId,
    required this.name,
    this.type,
    this.body,
    this.acidity,
    this.abv,
    this.country,
    this.region,
    this.winery,
    this.grapes = const [],
    this.harmonize = const [],
    required this.matchPercent,
    this.avgRating,
    this.ratingCount = 0,
    this.isFavorite = false,
    this.reasons = const [],
  });

  /// Retorna `null` se faltar `wine_id` ou `name` (item descartável).
  static RecommendedWineModel? tryParse(dynamic json) {
    final map = JsonUtils.asMap(json);
    if (map == null) return null;

    // `wine_id` é int no contrato, mas aceita String numérica/UUID.
    final rawId = map['wine_id'] ?? map['id'];
    final wineId =
        JsonUtils.readInt(rawId)?.toString() ?? JsonUtils.readString(rawId);
    final name = JsonUtils.readString(map['name']);
    if (wineId == null || name == null) return null;

    final match = JsonUtils.readDouble(map['match_percent']);
    final ratingCount = JsonUtils.readInt(map['rating_count']) ?? 0;

    return RecommendedWineModel(
      wineId: wineId,
      name: name,
      type: JsonUtils.readString(map['type']),
      body: JsonUtils.readString(map['body']),
      acidity: JsonUtils.readString(map['acidity']),
      abv: JsonUtils.readDouble(map['abv']),
      country: JsonUtils.readString(map['country']),
      region: JsonUtils.readString(map['region']),
      winery: JsonUtils.readString(map['winery']),
      grapes: JsonUtils.readStringList(map['grapes']),
      harmonize: JsonUtils.readStringList(map['harmonize']),
      matchPercent: match == null || !match.isFinite
          ? 0
          : match.round().clamp(0, 100).toInt(),
      avgRating: _readRating(map['avg_rating']),
      ratingCount: ratingCount < 0 ? 0 : ratingCount,
      isFavorite: JsonUtils.readBool(map['is_favorite']) ?? false,
      reasons: WineMatchReasonModel.tryParseList(map['reasons']),
    );
  }

  /// Faz o parse do corpo
  /// `{"source": ..., "profile": ..., "recommendations": [...]}`.
  /// Itens inválidos são descartados. Retorna `null` se o corpo não seguir o
  /// contrato (não é objeto ou `recommendations` não é lista).
  static List<RecommendedWineModel>? tryParseList(dynamic body) {
    final map = JsonUtils.asMap(body);
    if (map == null) return null;
    final rawList = JsonUtils.asList(map['recommendations']);
    if (rawList == null) return null;
    return rawList
        .map(tryParse)
        .whereType<RecommendedWineModel>()
        .toList(growable: false);
  }

  /// Média 0–10; valores fora da faixa ou não finitos viram `null`.
  static double? _readRating(dynamic value) {
    final rating = JsonUtils.readDouble(value);
    if (rating == null || !rating.isFinite || rating < 0 || rating > 10) {
      return null;
    }
    return rating;
  }

  RecommendedWine toEntity() => RecommendedWine(
        id: wineId,
        name: name,
        type: type,
        body: body,
        acidity: acidity,
        country: country,
        region: region,
        winery: winery,
        rating: avgRating,
        ratingCount: ratingCount,
        affinityPercentage: matchPercent,
        isFavorite: isFavorite,
        reasons: reasons.map((r) => r.toEntity()).toList(growable: false),
      );
}
