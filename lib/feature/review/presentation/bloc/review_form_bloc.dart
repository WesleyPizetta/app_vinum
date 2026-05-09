import 'package:essentials/essentials.dart';

import '../../domain/usecase/create_review.dart';
import '../../domain/usecase/delete_review.dart';
import '../../domain/usecase/get_review_tags.dart';
import '../../domain/usecase/update_review.dart';
import 'review_form_event.dart';
import 'review_form_state.dart';

class ReviewFormBloc extends Bloc<ReviewFormEvent, ReviewFormState> {
  final CreateReview _createReview;
  final UpdateReview _updateReview;
  final DeleteReview _deleteReview;
  final GetReviewTags _getReviewTags;

  ReviewFormBloc(
    this._createReview,
    this._updateReview,
    this._deleteReview,
    this._getReviewTags,
  ) : super(ReviewFormInitial()) {
    on<ReviewFormTagsRequested>(_onTagsRequested);
    on<ReviewFormSubmitted>(_onSubmitted);
    on<ReviewFormDeleted>(_onDeleted);
  }

  Future<void> _onTagsRequested(
    ReviewFormTagsRequested event,
    Emitter<ReviewFormState> emit,
  ) async {
    final result = await _getReviewTags(null);

    result.fold(
      (failure) => emit(ReviewFormError(message: _mapTagsFailure(failure))),
      (tags) => emit(ReviewFormTagsLoaded(tags: tags)),
    );
  }

  Future<void> _onSubmitted(
    ReviewFormSubmitted event,
    Emitter<ReviewFormState> emit,
  ) async {
    emit(ReviewFormLoading());

    if (event.reviewId != null) {
      final result = await _updateReview(UpdateReviewParams(
        id: event.reviewId!,
        nota: event.nota,
        comentario: event.comentario,
        tags: event.tags,
        token: event.token,
      ));
      result.fold(
        (failure) => emit(ReviewFormError(message: _mapSubmitFailure(failure))),
        (review) => emit(ReviewFormSuccess(review: review)),
      );
    } else {
      final result = await _createReview(CreateReviewParams(
        wineId: event.wineId,
        nota: event.nota,
        comentario: event.comentario,
        tags: event.tags,
        token: event.token,
      ));
      result.fold(
        (failure) => emit(ReviewFormError(message: _mapSubmitFailure(failure))),
        (review) => emit(ReviewFormSuccess(review: review)),
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
      (failure) => emit(ReviewFormError(message: _mapDeleteFailure(failure))),
      (_) => emit(ReviewFormSuccess(deletedReviewId: event.reviewId)),
    );
  }

  String _mapSubmitFailure(Failure failure) {
    final rawMessage = '${failure.error ?? ''}'.toLowerCase();
    if (rawMessage.contains('duplicate') ||
        rawMessage.contains('unique') ||
        rawMessage.contains('already') ||
        rawMessage.contains('já existe') ||
        (rawMessage.contains('409') && rawMessage.contains('avalia'))) {
      return 'Você já enviou uma avaliação para este vinho. Edite sua avaliação para atualizar os dados.';
    }

    if (failure is KnownFailure) {
      final message = (failure.message ?? '').toLowerCase();
      if (message.contains('invalid') ||
          message.contains('input') ||
          message.contains('nota') ||
          message.contains('wine_id')) {
        return 'Não foi possível enviar sua avaliação. Verifique os dados e tente novamente.';
      }
    }

    return 'Oops, parece que não foi possível enviar sua avaliação. Tente novamente';
  }

  String _mapDeleteFailure(Failure failure) {
    if (failure is KnownFailure) {
      final message = (failure.message ?? '').toLowerCase();
      if (message.contains('forbidden') || message.contains('unauthorized')) {
        return 'Você não tem permissão para excluir esta avaliação.';
      }
    }

    return 'Oops, parece que não foi possível excluir sua avaliação. Tente novamente';
  }

  String _mapTagsFailure(Failure failure) {
    if (failure is KnownFailure) {
      final message = (failure.message ?? '').toLowerCase();
      if (message.contains('unauthorized')) {
        return 'Sua sessão expirou. Faça login novamente para continuar.';
      }
    }

    return 'Oops, parece que não foi possível carregar as tags. Tente novamente';
  }
}
