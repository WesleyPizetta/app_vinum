import 'package:essentials/essentials.dart';

import '../../domain/usecase/sign_up.dart';
import 'register_event.dart';
import 'register_state.dart';

class RegisterBloc extends Bloc<RegisterEvent, RegisterState> {
  final SignUp _signUp;

  RegisterBloc(this._signUp) : super(RegisterInitial()) {
    on<RegisterSubmitted>(_onSubmitted);
  }

  Future<void> _onSubmitted(
    RegisterSubmitted event,
    Emitter<RegisterState> emit,
  ) async {
    emit(RegisterLoading());
    final result = await _signUp(
      SignUpParams(
        name: event.name,
        email: event.email,
        password: event.password,
      ),
    );
    result.fold(
      (failure) => emit(RegisterError(message: _mapFailureMessage(failure))),
      (user) => emit(RegisterSuccess(user: user)),
    );
  }

  String _mapFailureMessage(Failure failure) {
    if (failure is KnownFailure) {
      final msg = (failure.message ?? '').toLowerCase();
      if (msg.contains('already registered') || msg.contains('already exists')) {
        return 'auth_error_email_in_use';
      }
      if (msg.contains('password') && msg.contains('6')) {
        return 'auth_error_weak_password';
      }
    }
    return 'error_generic';
  }
}
