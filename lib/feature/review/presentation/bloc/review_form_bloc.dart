import 'package:essentials/essentials.dart';

import '../../domain/usecase/create_review.dart';
import '../../domain/usecase/delete_review.dart';
import '../../domain/usecase/update_review.dart';
import 'review_form_event.dart';
import 'review_form_state.dart';

class ReviewFormBloc extends Bloc<ReviewFormEvent, ReviewFormState> {
  final CreateReview _createReview;
  final UpdateReview _updateReview;
  final DeleteReview _deleteReview;

  ReviewFormBloc(this._createReview, this._updateReview, this._deleteReview)
      : super(ReviewFormInitial()) {
    on<ReviewFormSubmitted>(_onSubmitted);
    on<ReviewFormDeleted>(_onDeleted);
  }

  Future<void> _onSubmitted(
    ReviewFormSubmitted event,
    Emitter<ReviewFormState> emit,
  ) async {
    emit(ReviewFormLoading());

    if (event.reviewId != null && event.token != null) {
      final result = await _updateReview(UpdateReviewParams(
        id: event.reviewId!,
        nota: event.nota,
        comentario: event.comentario,
        token: event.token!,
      ));
      result.fold(
        (failure) => emit(ReviewFormError(message: failure.toString())),
        (_) => emit(ReviewFormSuccess()),
      );
    } else {
      final result = await _createReview(CreateReviewParams(
        wineId: event.wineId,
        usuarioId: event.usuarioId,
        nota: event.nota,
        comentario: event.comentario,
        token: event.token,
      ));
      result.fold(
        (failure) => emit(ReviewFormError(message: failure.toString())),
        (_) => emit(ReviewFormSuccess()),
      );
    }
  }

  Future<void> _onDeleted(
    ReviewFormDeleted event,
    Emitter<ReviewFormState> emit,
  ) async {
    emit(ReviewFormLoading());

    final result = await _deleteReview(
      DeleteReviewParams(id: event.reviewId, token: event.token),
    );

    result.fold(
      (failure) => emit(ReviewFormError(message: failure.toString())),
      (_) => emit(ReviewFormSuccess()),
    );
  }
}
