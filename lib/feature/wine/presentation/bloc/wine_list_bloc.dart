import 'package:essentials/essentials.dart';

import '../../domain/entity/wine_failure_code.dart';
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
      (failure) => emit(WineListError(message: _mapFailure(failure))),
      (wines) => emit(WineListLoaded(wines: wines)),
    );
  }

  /// Traduz a falha para uma chave i18n (exibida com `getString`).
  String _mapFailure(Failure failure) {
    if (failure is KnownFailure) {
      return failure.code == WineFailureCode.server
          ? 'wine_error_server'
          : 'wine_error_load';
    }
    return 'wine_error_connection';
  }
}
