import 'package:essentials/essentials.dart';

import '../../../auth/domain/repository/auth_repository.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final AuthRepository _authRepository;

  HomeBloc(this._authRepository) : super(HomeInitial()) {
    on<HomeStarted>(_onStarted);
  }

  Future<void> _onStarted(HomeStarted event, Emitter<HomeState> emit) async {
    emit(HomeLoading());
    await Future.delayed(const Duration(milliseconds: 500));
    emit(HomeLoaded(
      welcomeMessage: 'Vinum',
      currentUser: _authRepository.getCurrentUser(),
    ));
  }
}
