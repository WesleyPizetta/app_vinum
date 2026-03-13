import '../../domain/entity/wine.dart';

class WineModel {
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

  const WineModel({
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

  factory WineModel.fromJson(Map<String, dynamic> json) {
    return WineModel(
      id: json['id'] as String,
      name: json['name'] as String,
      winery: json['winery'] as String,
      region: json['region'] as String,
      country: json['country'] as String,
      grape: json['grape'] as String,
      vintage: json['vintage'] as int,
      rating: (json['rating'] as num).toDouble(),
      imageUrl: json['imageUrl'] as String,
      description: json['description'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'winery': winery,
      'region': region,
      'country': country,
      'grape': grape,
      'vintage': vintage,
      'rating': rating,
      'imageUrl': imageUrl,
      'description': description,
    };
  }

  Wine toEntity() {
    return Wine(
      id: id,
      name: name,
      winery: winery,
      region: region,
      country: country,
      grape: grape,
      vintage: vintage,
      rating: rating,
      imageUrl: imageUrl,
      description: description,
    );
  }

  factory WineModel.fromEntity(Wine entity) {
    return WineModel(
      id: entity.id,
      name: entity.name,
      winery: entity.winery,
      region: entity.region,
      country: entity.country,
      grape: entity.grape,
      vintage: entity.vintage,
      rating: entity.rating,
      imageUrl: entity.imageUrl,
      description: entity.description,
    );
  }
}
