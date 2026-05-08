import '../../domain/entity/review.dart';

class ReviewModel {
  final String id;
  final int wineId;
  final String usuarioId;
  final double nota;
  final String? comentario;
  final DateTime createdAt;

  const ReviewModel({
    required this.id,
    required this.wineId,
    required this.usuarioId,
    required this.nota,
    this.comentario,
    required this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'] as String,
      wineId: json['wine_id'] as int,
      usuarioId: json['usuario_id'] as String,
      nota: (json['nota'] as num).toDouble(),
      comentario: json['comentario'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Review toEntity() => Review(
        id: id,
        wineId: wineId,
        usuarioId: usuarioId,
        nota: nota,
        comentario: comentario,
        createdAt: createdAt,
      );
}
