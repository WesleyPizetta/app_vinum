import 'package:essentials/essentials.dart';

import '../../domain/usecase/get_collections.dart';
import 'collections_event.dart';
import 'collections_state.dart';

class CollectionsBloc extends Bloc<CollectionsEvent, CollectionsState> {
  final GetCollections _getCollections;

  CollectionsBloc(this._getCollections) : super(CollectionsInitial()) {
    on<CollectionsStarted>(_onStarted);
  }

  Future<void> _onStarted(
    CollectionsStarted event,
    Emitter<CollectionsState> emit,
  ) async {
    emit(CollectionsLoading());

    final result = await _getCollections();

    result.fold(
      (failure) => emit(CollectionsError(message: failure.toString())),
      (collections) => emit(CollectionsLoaded(collections: collections)),
    );
  }
}
