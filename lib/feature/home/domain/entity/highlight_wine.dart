/// Vinho da seção "Destaques da Semana" da home
/// (`GET /v1/wines/highlights`).
///
/// [rating] é a média das avaliações do app (0–10) e é `null` quando o vinho
/// ainda não tem avaliações. [isFavorite] vem do cache de favoritos (o
/// endpoint é público e não informa `is_favorite`).
class HighlightWine {
  final String id;
  final String name;

  /// Tipo como vem da API ("Red", "White", ...); a tradução e a cor do
  /// banner são decididas na apresentação.
  final String? type;
  final String? region;
  final String? country;
  final double? rating;
  final int ratingCount;
  final bool isFavorite;

  const HighlightWine({
    required this.id,
    required this.name,
    this.type,
    this.region,
    this.country,
    this.rating,
    this.ratingCount = 0,
    this.isFavorite = false,
  });

  bool get hasRating => rating != null && ratingCount > 0;

  HighlightWine copyWith({bool? isFavorite}) {
    return HighlightWine(
      id: id,
      name: name,
      type: type,
      region: region,
      country: country,
      rating: rating,
      ratingCount: ratingCount,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
