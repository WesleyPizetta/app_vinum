import 'package:essentials/essentials.dart';

import '../../../home/domain/usecase/get_wine_match.dart';
import 'wine_match_event.dart';
import 'wine_match_state.dart';

/// Carrega `GET /v1/me/wines/{id}/match` para a seção "Por que este vinho
/// combina com você?" do detalhe do vinho.
///
/// Falhas conhecidas (409 sem quiz, 404, 401, 5xx, contrato inválido)
/// ocultam a seção; só falhas de conexão ([UnknownFailure]) oferecem
/// "tentar novamente".
class WineMatchBloc extends Bloc<WineMatchEvent, WineMatchState> {
  final GetWineMatch _getWineMatch;

  WineMatchBloc(this._getWineMatch) : super(WineMatchInitial()) {
    on<WineMatchStarted>(_onStarted);
  }

  Future<void> _onStarted(
    WineMatchStarted event,
    Emitter<WineMatchState> emit,
  ) async {
    if (state is WineMatchLoading) return;
    emit(WineMatchLoading());

    final result = await _getWineMatch(event.wineId);

    result.fold(
      (failure) => emit(
        failure is KnownFailure ? WineMatchHidden() : WineMatchError(),
      ),
      (match) => emit(WineMatchLoaded(match: match)),
    );
  }
}
