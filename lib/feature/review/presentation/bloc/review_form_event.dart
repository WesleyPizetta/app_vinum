sealed class ReviewFormEvent {}

class ReviewFormSubmitted extends ReviewFormEvent {
  final String wineId;
  final String usuarioId;
  final double nota;
  final String? comentario;
  final String? token;
  final String? reviewId;

  ReviewFormSubmitted({
    required this.wineId,
    required this.usuarioId,
    required this.nota,
    this.comentario,
    this.token,
    this.reviewId,
  });
}

class ReviewFormDeleted extends ReviewFormEvent {
  final String reviewId;
  final String token;

  ReviewFormDeleted({required this.reviewId, required this.token});
}
