import '../../../wine/domain/entity/wine.dart';

/// Uma avaliação do usuário em `GET /v1/me/reviews` ("Minha adega").
class CellarReview {
  /// Id (UUID) da avaliação.
  final String id;

  /// Id do vinho (mesmo formato de `Wine.id`), usado para abrir o detalhe
  /// mesmo quando [wine] não veio na resposta.
  final String wineId;

  /// Nota dada pelo usuário (0–10).
  final double rating;

  /// Comentário (`null` quando vazio).
  final String? comment;

  /// Códigos das tags como vieram da API (ex.: `frutado`).
  final List<String> tags;

  final DateTime? createdAt;

  /// Dados do vinho; `null` se o vinho não existe mais na base.
  final Wine? wine;

  const CellarReview({
    required this.id,
    required this.wineId,
    required this.rating,
    this.comment,
    this.tags = const [],
    this.createdAt,
    this.wine,
  });
}
