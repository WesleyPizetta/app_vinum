import 'package:essentials/essentials.dart';

import '../../domain/usecase/get_wines.dart';
import 'wine_list_event.dart';
import 'wine_list_state.dart';

class WineListBloc extends Bloc<WineListEvent, WineListState> {
  final GetWines _getWines;

  WineListBloc(this._getWines) : super(WineListInitial()) {
    on<WineListStarted>(_onStarted);
  }

  Future<void> _onStarted(
    WineListStarted event,
    Emitter<WineListState> emit,
  ) async {
    emit(WineListLoading());

    final result = await _getWines();

    result.fold(
      (failure) => emit(WineListError(message: failure.toString())),
      (wines) => emit(WineListLoaded(wines: wines)),
    );
  }
}
