import '../../domain/entity/explore_item.dart';

class ExploreItemModel {
  final String id;
  final String name;
  final String winery;
  final int vintage;
  final double rating;

  const ExploreItemModel({
    required this.id,
    required this.name,
    required this.winery,
    required this.vintage,
    required this.rating,
  });

  ExploreItem toEntity() => ExploreItem(
        id: id,
        name: name,
        winery: winery,
        vintage: vintage,
        rating: rating,
      );
}
