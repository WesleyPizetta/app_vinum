import 'package:essentials/essentials.dart';

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
      (failure) => emit(WineDetailError(message: failure.toString())),
      (wine) => emit(WineDetailLoaded(wine: wine)),
    );
  }
}
