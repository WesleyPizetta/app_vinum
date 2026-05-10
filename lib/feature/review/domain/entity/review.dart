import 'review_tag.dart';

class Review {
  final String id;
  final int wineId;
  final String usuarioId;
  final String? usuarioNome;
  final double nota;
  final String? comentario;
  final List<ReviewTag> tags;
  final DateTime createdAt;

  const Review({
    required this.id,
    required this.wineId,
    required this.usuarioId,
    this.usuarioNome,
    required this.nota,
    this.comentario,
    this.tags = const [],
    required this.createdAt,
  });
}
