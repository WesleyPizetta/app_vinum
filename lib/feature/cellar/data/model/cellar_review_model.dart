import '../../../../core/utils/json_utils.dart';
import '../../../wine/data/model/wine_model.dart';
import '../../domain/entity/cellar_review.dart';

/// Item de `reviews` em `GET /v1/me/reviews`:
/// `{id, wine_id, nota, comentario, tags[], created_at, wine}`, onde `wine`
/// segue o contrato de `GET /v1/wines/{id}` (ou é `null`).
class CellarReviewModel {
  final String id;
  final String wineId;
  final double rating;
  final String? comment;
  final List<String> tags;
  final DateTime? createdAt;
  final WineModel? wine;

  const CellarReviewModel({
    required this.id,
    required this.wineId,
    required this.rating,
    this.comment,
    this.tags = const [],
    this.createdAt,
    this.wine,
  });

  /// Retorna `null` se faltar `id`, `wine_id` (e o vinho embutido) ou uma
  /// `nota` numérica. A nota é limitada a 0–10.
  static CellarReviewModel? tryParse(dynamic json) {
    final map = JsonUtils.asMap(json);
    if (map == null) return null;

    final id = _readId(map['id']);
    if (id == null) return null;

    final wine = WineModel.tryParse(map['wine']);
    final wineId = _readId(map['wine_id']) ?? wine?.id;
    if (wineId == null) return null;

    final rawRating = JsonUtils.readDouble(map['nota']);
    if (rawRating == null || !rawRating.isFinite) return null;
    final rating = rawRating.clamp(0.0, 10.0).toDouble();

    final rawDate = JsonUtils.readString(map['created_at']);

    return CellarReviewModel(
      id: id,
      wineId: wineId,
      rating: rating,
      comment: JsonUtils.readString(map['comentario']),
      tags: JsonUtils.readStringList(map['tags']),
      createdAt: rawDate == null ? null : DateTime.tryParse(rawDate),
      wine: wine,
    );
  }

  /// Aceita int (ex.: `wine_id`) ou String (ex.: UUID).
  static String? _readId(dynamic raw) =>
      JsonUtils.readInt(raw)?.toString() ?? JsonUtils.readString(raw);

  CellarReview toEntity() => CellarReview(
        id: id,
        wineId: wineId,
        rating: rating,
        comment: comment,
        tags: tags,
        createdAt: createdAt,
        wine: wine?.toEntity(),
      );
}
