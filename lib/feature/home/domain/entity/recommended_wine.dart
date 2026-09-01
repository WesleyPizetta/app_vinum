class RecommendedWine {
  final String id;
  final String name;
  final double rating;
  final double price;
  final int affinityPercentage;
  final bool isFavorite;

  const RecommendedWine({
    required this.id,
    required this.name,
    required this.rating,
    required this.price,
    required this.affinityPercentage,
    this.isFavorite = false,
  });

  RecommendedWine copyWith({
    String? id,
    String? name,
    double? rating,
    double? price,
    int? affinityPercentage,
    bool? isFavorite,
  }) {
    return RecommendedWine(
      id: id ?? this.id,
      name: name ?? this.name,
      rating: rating ?? this.rating,
      price: price ?? this.price,
      affinityPercentage: affinityPercentage ?? this.affinityPercentage,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
