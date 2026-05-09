import '../../domain/entity/review_tag.dart';

sealed class ReviewFormState {}

class ReviewFormInitial extends ReviewFormState {}

class ReviewFormTagsLoaded extends ReviewFormState {
  final List<ReviewTagOption> tags;

  ReviewFormTagsLoaded({required this.tags});
}

class ReviewFormLoading extends ReviewFormState {}

class ReviewFormSuccess extends ReviewFormState {}

class ReviewFormError extends ReviewFormState {
  final String message;
  ReviewFormError({required this.message});
}
