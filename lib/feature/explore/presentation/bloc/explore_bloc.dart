import 'package:essentials/essentials.dart';

import '../../domain/usecase/get_explore_items.dart';
import 'explore_event.dart';
import 'explore_state.dart';

class ExploreBloc extends Bloc<ExploreEvent, ExploreState> {
  final GetExploreItems _getExploreItems;

  ExploreBloc(this._getExploreItems) : super(ExploreInitial()) {
    on<ExploreStarted>(_onStarted);
  }

  Future<void> _onStarted(
    ExploreStarted event,
    Emitter<ExploreState> emit,
  ) async {
    emit(ExploreLoading());

    final result = await _getExploreItems();

    result.fold(
      (failure) => emit(ExploreError(message: failure.toString())),
      (items) => emit(ExploreLoaded(items: items)),
    );
  }
}
