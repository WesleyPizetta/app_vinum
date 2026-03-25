import 'package:essentials/essentials.dart';
import 'package:flutter/foundation.dart';

import '../../domain/repository/auth_repository.dart';
import '../../domain/usecase/sign_in.dart';
import 'login_event.dart';
import 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final SignIn _signIn;
  final AuthRepository _authRepository;

  LoginBloc(this._signIn, this._authRepository) : super(LoginInitial()) {
    on<LoginSessionChecked>(_onSessionChecked);
    on<LoginSubmitted>(_onSubmitted);
    on<LoginSocialSubmitted>(_onSocialSubmitted);
  }

  void _onSessionChecked(
    LoginSessionChecked event,
    Emitter<LoginState> emit,
  ) {
    final user = _authRepository.getCurrentUser();
    if (user != null) emit(LoginSuccess(user: user));
  }

  Future<void> _onSubmitted(
    LoginSubmitted event,
    Emitter<LoginState> emit,
  ) async {
    emit(LoginLoading());
    final result = await _signIn(
      SignInParams(email: event.email, password: event.password),
    );
    result.fold(
      (failure) => emit(LoginError(message: _mapFailureMessage(failure))),
      (user) => emit(LoginSuccess(user: user)),
    );
  }

  Future<void> _onSocialSubmitted(
    LoginSocialSubmitted event,
    Emitter<LoginState> emit,
  ) async {
    debugPrint('[GoogleBFF] Bloc._onSocialSubmitted: provider=${event.provider}');
    emit(LoginLoading());
    final result = await _authRepository.signInWithSocial(
      provider: event.provider,
      idToken: event.idToken,
      nonce: event.nonce,
    );
    result.fold(
      (failure) {
        debugPrint('[GoogleBFF] Bloc: falha -> ${failure.runtimeType} | ${failure is KnownFailure ? failure.message : failure}');
        emit(LoginError(message: _mapFailureMessage(failure)));
      },
      (user) {
        debugPrint('[GoogleBFF] Bloc: sucesso -> user.id=${user.id}  email=${user.email}');
        emit(LoginSuccess(user: user));
      },
    );
  }

  String _mapFailureMessage(Failure failure) {
    if (failure is KnownFailure) {
      final msg = (failure.message ?? '').toLowerCase();
      if (msg.contains('invalid') || msg.contains('credentials')) {
        return 'auth_error_invalid_credentials';
      }
      if (msg.contains('email not confirmed')) {
        return 'auth_error_email_not_confirmed';
      }
      if (msg.contains('social') || msg.contains('token')) {
        return 'auth_error_social_login_failed';
      }
    }
    return 'error_generic';
  }
}
