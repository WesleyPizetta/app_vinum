import 'package:essentials/essentials.dart';

import '../../domain/entity/wine_failure_code.dart';
import '../../domain/usecase/get_wine_by_id.dart';
import 'wine_detail_event.dart';
import 'wine_detail_state.dart';

class WineDetailBloc extends Bloc<WineDetailEvent, WineDetailState> {
  final GetWineById _getWineById;

  WineDetailBloc(this._getWineById) : super(WineDetailInitial()) {
    on<WineDetailStarted>(_onStarted);
  }

  Future<void> _onStarted(
    WineDetailStarted event,
    Emitter<WineDetailState> emit,
  ) async {
    emit(WineDetailLoading());

    final result = await _getWineById(event.wineId);

    result.fold(
      (failure) => emit(WineDetailError(message: _mapFailure(failure))),
      (wine) => emit(WineDetailLoaded(wine: wine)),
    );
  }

  /// Traduz a falha para uma chave i18n (exibida com `getString`).
  String _mapFailure(Failure failure) {
    if (failure is KnownFailure) {
      return switch (failure.code) {
        WineFailureCode.notFound => 'wine_error_not_found',
        WineFailureCode.server => 'wine_error_server',
        _ => 'wine_error_load',
      };
    }
    return 'wine_error_connection';
  }
}
