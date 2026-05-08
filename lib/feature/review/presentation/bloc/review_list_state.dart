import '../../domain/entity/review.dart';

sealed class ReviewListState {}

class ReviewListInitial extends ReviewListState {}

class ReviewListLoading extends ReviewListState {}

class ReviewListLoaded extends ReviewListState {
  final List<Review> reviews;
  ReviewListLoaded({required this.reviews});
}

class ReviewListError extends ReviewListState {
  final String message;
  ReviewListError({required this.message});
}
