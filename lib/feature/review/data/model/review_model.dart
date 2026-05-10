import '../../domain/entity/review.dart';
import '../../domain/entity/review_tag.dart';

class ReviewModel {
  final String id;
  final int wineId;
  final String usuarioId;
  final String? usuarioNome;
  final double nota;
  final String? comentario;
  final List<ReviewTag> tags;
  final DateTime createdAt;

  const ReviewModel({
    required this.id,
    required this.wineId,
    required this.usuarioId,
    this.usuarioNome,
    required this.nota,
    this.comentario,
    this.tags = const [],
    required this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    final parsedTags = (json['tags'] as List<dynamic>? ?? const [])
        .map((e) => ReviewTag.fromCode(e as String? ?? ''))
        .whereType<ReviewTag>()
        .toList();

    return ReviewModel(
      id: json['id'] as String,
      wineId: json['wine_id'] as int,
      usuarioId: json['usuario_id'] as String,
      usuarioNome: json['usuario_nome'] as String?,
      nota: (json['nota'] as num).toDouble(),
      comentario: json['comentario'] as String?,
      tags: parsedTags,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Review toEntity() => Review(
        id: id,
        wineId: wineId,
        usuarioId: usuarioId,
        usuarioNome: usuarioNome,
        nota: nota,
        comentario: comentario,
        tags: tags,
        createdAt: createdAt,
      );
}
