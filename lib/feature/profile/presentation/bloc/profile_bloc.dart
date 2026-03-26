import 'package:essentials/essentials.dart';

import '../../../auth/domain/repository/auth_repository.dart';
import '../../../auth/domain/usecase/logout.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final AuthRepository _authRepository;
  final Logout _logout;

  ProfileBloc(this._authRepository, this._logout) : super(ProfileInitial()) {
    on<ProfileStarted>(_onStarted);
    on<ProfileLogoutRequested>(_onLogoutRequested);
  }

  void _onStarted(
    ProfileStarted event,
    Emitter<ProfileState> emit,
  ) {
    final user = _authRepository.getCurrentUser();
    if (user != null) {
      emit(ProfileLoaded(user: user));
    } else {
      emit(ProfileError(message: 'error_generic'));
    }
  }

  Future<void> _onLogoutRequested(
    ProfileLogoutRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoggingOut());
    final result = await _logout();
    result.fold(
      (failure) => emit(ProfileError(message: 'error_generic')),
      (_) => emit(ProfileLoggedOut()),
    );
  }
}
