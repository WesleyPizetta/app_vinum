import '../../domain/entity/review.dart';

sealed class ReviewListEvent {}

class ReviewListStarted extends ReviewListEvent {
  final String wineId;
  ReviewListStarted({required this.wineId});
}

class ReviewListUpserted extends ReviewListEvent {
  final Review review;

  ReviewListUpserted({required this.review});
}

class ReviewListRemoved extends ReviewListEvent {
  final String reviewId;

  ReviewListRemoved({required this.reviewId});
}
