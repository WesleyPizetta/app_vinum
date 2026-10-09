class Wine {
  final String id;
  final String name;
  final String winery;
  final String region;
  final String country;

  /// Uvas separadas por vírgula (ex.: "Cabernet Sauvignon, Merlot").
  final String grape;

  /// Safra mais recente conhecida; `0` quando não há safra.
  final int vintage;

  /// Média das avaliações do app (0–10). Só é significativa quando
  /// [ratingCount] > 0.
  final double rating;
  final int ratingCount;
  final String imageUrl;
  final String description;

  /// Tipo como vem da API: Red, White, Sparkling, Rosé, Dessert...
  final String type;
  final String body;
  final String acidity;
  final double? abv;

  /// Harmonizações (em inglês, como vêm da base): Beef, Pasta, Shellfish...
  final List<String> harmonize;

  const Wine({
    required this.id,
    required this.name,
    required this.winery,
    required this.region,
    required this.country,
    required this.grape,
    required this.vintage,
    required this.rating,
    required this.imageUrl,
    required this.description,
    this.ratingCount = 0,
    this.type = '',
    this.body = '',
    this.acidity = '',
    this.abv,
    this.harmonize = const [],
  });

  bool get hasRating => ratingCount > 0;
}
