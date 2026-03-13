class Wine {
  final String id;
  final String name;
  final String winery;
  final String region;
  final String country;
  final String grape;
  final int vintage;
  final double rating;
  final String imageUrl;
  final String description;

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
  });
}
