import '../../domain/entity/review_tag.dart';

sealed class ReviewFormEvent {}

class ReviewFormTagsRequested extends ReviewFormEvent {}

class ReviewFormSubmitted extends ReviewFormEvent {
  final String wineId;
  final double nota;
  final String? comentario;
  final List<ReviewTag> tags;
  final String token;
  final String? reviewId;

  ReviewFormSubmitted({
    required this.wineId,
    required this.nota,
    this.comentario,
    this.tags = const [],
    required this.token,
    this.reviewId,
  });
}

class ReviewFormDeleted extends ReviewFormEvent {
  final String reviewId;
  final String token;

  ReviewFormDeleted({required this.reviewId, required this.token});
}
