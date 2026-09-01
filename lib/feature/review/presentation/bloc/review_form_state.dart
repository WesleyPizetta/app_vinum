import '../../domain/entity/review.dart';
import '../../domain/entity/review_tag.dart';

sealed class ReviewFormState {}

enum ReviewFormOperation {
  submit,
  delete,
  tags,
}

class ReviewFormInitial extends ReviewFormState {}

class ReviewFormTagsLoaded extends ReviewFormState {
  final List<ReviewTagOption> tags;

  ReviewFormTagsLoaded({required this.tags});
}

class ReviewFormLoading extends ReviewFormState {
  final ReviewFormOperation operation;

  ReviewFormLoading({required this.operation});
}

class ReviewFormSuccess extends ReviewFormState {
  final Review? review;
  final String? deletedReviewId;
  final ReviewFormOperation operation;

  ReviewFormSuccess({
    this.review,
    this.deletedReviewId,
    required this.operation,
  });
}

class ReviewFormError extends ReviewFormState {
  final String message;
  final ReviewFormOperation operation;

  ReviewFormError({
    required this.message,
    required this.operation,
  });
}
