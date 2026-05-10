import 'package:essentials/essentials.dart';

import '../../domain/entity/review.dart';
import '../../domain/usecase/get_wine_reviews.dart';
import 'review_list_event.dart';
import 'review_list_state.dart';

class ReviewListBloc extends Bloc<ReviewListEvent, ReviewListState> {
  final GetWineReviews _getWineReviews;

  ReviewListBloc(this._getWineReviews) : super(ReviewListInitial()) {
    on<ReviewListStarted>(_onStarted);
    on<ReviewListUpserted>(_onUpserted);
    on<ReviewListRemoved>(_onRemoved);
  }

  Future<void> _onStarted(
    ReviewListStarted event,
    Emitter<ReviewListState> emit,
  ) async {
    emit(ReviewListLoading());

    final result = await _getWineReviews(event.wineId);

    result.fold(
      (failure) => emit(ReviewListError(message: failure.toString())),
      (reviews) => emit(ReviewListLoaded(reviews: _sortByNewest(reviews))),
    );
  }

  void _onUpserted(
    ReviewListUpserted event,
    Emitter<ReviewListState> emit,
  ) {
    if (state is! ReviewListLoaded) {
      emit(ReviewListLoaded(reviews: [event.review]));
      return;
    }

    final current = (state as ReviewListLoaded).reviews;
    final next = <Review>[
      event.review,
      ...current.where((item) => item.id != event.review.id),
    ];

    emit(ReviewListLoaded(reviews: _sortByNewest(next)));
  }

  void _onRemoved(
    ReviewListRemoved event,
    Emitter<ReviewListState> emit,
  ) {
    if (state is! ReviewListLoaded) {
      return;
    }

    final current = (state as ReviewListLoaded).reviews;
    final next = current.where((item) => item.id != event.reviewId).toList();
    emit(ReviewListLoaded(reviews: next));
  }

  List<Review> _sortByNewest(List<Review> reviews) {
    final sorted = [...reviews];
    sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted;
  }
}
