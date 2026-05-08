import 'package:essentials/essentials.dart';

import '../../domain/usecase/get_wine_reviews.dart';
import 'review_list_event.dart';
import 'review_list_state.dart';

class ReviewListBloc extends Bloc<ReviewListEvent, ReviewListState> {
  final GetWineReviews _getWineReviews;

  ReviewListBloc(this._getWineReviews) : super(ReviewListInitial()) {
    on<ReviewListStarted>(_onStarted);
  }

  Future<void> _onStarted(
    ReviewListStarted event,
    Emitter<ReviewListState> emit,
  ) async {
    emit(ReviewListLoading());

    final result = await _getWineReviews(event.wineId);

    result.fold(
      (failure) => emit(ReviewListError(message: failure.toString())),
      (reviews) => emit(ReviewListLoaded(reviews: reviews)),
    );
  }
}
