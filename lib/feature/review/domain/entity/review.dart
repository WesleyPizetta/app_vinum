class Review {
  final String id;
  final int wineId;
  final String usuarioId;
  final double nota;
  final String? comentario;
  final DateTime createdAt;

  const Review({
    required this.id,
    required this.wineId,
    required this.usuarioId,
    required this.nota,
    this.comentario,
    required this.createdAt,
  });
}
