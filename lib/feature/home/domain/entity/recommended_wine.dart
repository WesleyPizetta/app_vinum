import 'wine_match_reason.dart';

/// Vinho recomendado para o usuário (seção "Sugestões para você" da home).
///
/// [rating] é a média das avaliações do app na escala 0–10 (mesma escala do
/// feature de reviews) e é `null` quando o vinho ainda não tem avaliações.
/// [isFavorite] vem de `is_favorite` da API e é mantido em sincronia com o
/// cache de favoritos (`FavoritesRepository`) pelos blocs.
class RecommendedWine {
  final String id;
  final String name;

  /// Tipo como vem da API (ex.: "Red", "White", "Sparkling", "Rosé",
  /// "Dessert", "Dessert/Port"). A tradução é feita na apresentação.
  final String? type;
  final String? body;
  final String? acidity;
  final String? country;
  final String? region;
  final String? winery;
  final double? rating;
  final int ratingCount;

  /// Percentual de afinidade com o perfil do usuário (0–100).
  final int affinityPercentage;
  final bool isFavorite;

  /// Motivos da recomendação (positivos primeiro). Vazio quando a API não
  /// envia `reasons`.
  final List<WineMatchReason> reasons;

  const RecommendedWine({
    required this.id,
    required this.name,
    this.type,
    this.body,
    this.acidity,
    this.country,
    this.region,
    this.winery,
    this.rating,
    this.ratingCount = 0,
    required this.affinityPercentage,
    this.isFavorite = false,
    this.reasons = const [],
  });

  bool get hasRating => rating != null && ratingCount > 0;

  RecommendedWine copyWith({bool? isFavorite}) {
    return RecommendedWine(
      id: id,
      name: name,
      type: type,
      body: body,
      acidity: acidity,
      country: country,
      region: region,
      winery: winery,
      rating: rating,
      ratingCount: ratingCount,
      affinityPercentage: affinityPercentage,
      isFavorite: isFavorite ?? this.isFavorite,
      reasons: reasons,
    );
  }
}
