import '../../../../core/utils/json_utils.dart';
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
  final int ratingCount;
  final String imageUrl;
  final String description;
  final String type;
  final String body;
  final String acidity;
  final double? abv;
  final List<String> harmonize;

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
    this.ratingCount = 0,
    this.type = '',
    this.body = '',
    this.acidity = '',
    this.abv,
    this.harmonize = const [],
  });

  /// Converte o contrato do BFF (`GET /v1/wines/{id}`):
  /// `{wine_id, name, type, elaborate, body, acidity, abv, country, region,
  /// winery, grapes[], harmonize[], vintages[], avg_rating, rating_count}`.
  /// Retorna `null` se faltar id ou nome.
  static WineModel? tryParse(dynamic raw) {
    final json = JsonUtils.asMap(JsonUtils.decode(raw));
    if (json == null) return null;

    final id =
        JsonUtils.readInt(json['wine_id']) ?? JsonUtils.readInt(json['id']);
    final name = JsonUtils.readString(json['name']);
    if (id == null || name == null || name.isEmpty) return null;

    final vintages = (JsonUtils.asList(json['vintages']) ?? const [])
        .map(JsonUtils.readInt)
        .whereType<int>()
        .toList();
    final ratingCount = JsonUtils.readInt(json['rating_count']) ?? 0;

    return WineModel(
      id: id.toString(),
      name: name,
      winery: JsonUtils.readString(json['winery']) ?? '',
      region: JsonUtils.readString(json['region']) ?? '',
      country: JsonUtils.readString(json['country']) ?? '',
      grape: JsonUtils.readStringList(json['grapes']).join(', '),
      vintage: vintages.isEmpty ? 0 : vintages.reduce((a, b) => a > b ? a : b),
      rating: ratingCount > 0
          ? (JsonUtils.readDouble(json['avg_rating']) ?? 0)
          : 0,
      ratingCount: ratingCount,
      imageUrl: '',
      description: JsonUtils.readString(json['elaborate']) ?? '',
      type: JsonUtils.readString(json['type']) ?? '',
      body: JsonUtils.readString(json['body']) ?? '',
      acidity: JsonUtils.readString(json['acidity']) ?? '',
      abv: JsonUtils.readDouble(json['abv']),
      harmonize: JsonUtils.readStringList(json['harmonize']),
    );
  }

  /// Lista (`GET /v1/wines`). Itens inválidos são ignorados; `null` se o
  /// corpo não for uma lista.
  static List<WineModel>? tryParseList(dynamic raw) {
    final list = JsonUtils.asList(JsonUtils.decode(raw));
    if (list == null) return null;
    return list.map(tryParse).whereType<WineModel>().toList();
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
      ratingCount: ratingCount,
      imageUrl: imageUrl,
      description: description,
      type: type,
      body: body,
      acidity: acidity,
      abv: abv,
      harmonize: harmonize,
    );
  }
}
