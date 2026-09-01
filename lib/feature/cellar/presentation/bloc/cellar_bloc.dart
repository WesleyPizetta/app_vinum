import 'package:essentials/essentials.dart';

import '../../domain/usecase/get_cellar_items.dart';
import 'cellar_event.dart';
import 'cellar_state.dart';

class CellarBloc extends Bloc<CellarEvent, CellarState> {
  final GetCellarItems _getCellarItems;

  CellarBloc(this._getCellarItems) : super(CellarInitial()) {
    on<CellarStarted>(_onStarted);
  }

  Future<void> _onStarted(
    CellarStarted event,
    Emitter<CellarState> emit,
  ) async {
    emit(CellarLoading());

    final result = await _getCellarItems();

    result.fold(
      (failure) => emit(CellarError(message: failure.toString())),
      (items) => emit(CellarLoaded(items: items)),
    );
  }
}
