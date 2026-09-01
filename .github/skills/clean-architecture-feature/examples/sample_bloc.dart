import 'package:essentials/essentials.dart';

import '../../domain/entity/sample_entity.dart';
import '../../domain/usecase/get_sample_items.dart';

// --- Events ---
sealed class SampleEvent {}

class SampleStarted extends SampleEvent {}

// --- States ---
sealed class SampleState {}

class SampleInitial extends SampleState {}

class SampleLoading extends SampleState {}

class SampleLoaded extends SampleState {
  final List<SampleEntity> items;

  SampleLoaded({required this.items});
}

class SampleError extends SampleState {
  final String message;

  SampleError({required this.message});
}

// --- BLoC ---
class SampleBloc extends Bloc<SampleEvent, SampleState> {
  final GetSampleItems _getSampleItems;

  SampleBloc(this._getSampleItems) : super(SampleInitial()) {
    on<SampleStarted>(_onStarted);
  }

  Future<void> _onStarted(
    SampleStarted event,
    Emitter<SampleState> emit,
  ) async {
    emit(SampleLoading());

    final result = await _getSampleItems();

    result.fold(
      (failure) => emit(SampleError(message: failure.toString())),
      (items) => emit(SampleLoaded(items: items)),
    );
  }
}
