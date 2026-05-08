sealed class ReviewFormState {}

class ReviewFormInitial extends ReviewFormState {}

class ReviewFormLoading extends ReviewFormState {}

class ReviewFormSuccess extends ReviewFormState {}

class ReviewFormError extends ReviewFormState {
  final String message;
  ReviewFormError({required this.message});
}
