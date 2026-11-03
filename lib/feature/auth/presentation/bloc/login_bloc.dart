import 'package:essentials/essentials.dart';
import 'package:flutter/foundation.dart';

import '../../domain/entity/user.dart';
import '../../domain/repository/auth_repository.dart';
import '../../domain/usecase/ensure_user_nickname.dart';
import '../../domain/usecase/sign_in.dart';
import 'login_event.dart';
import 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final SignIn _signIn;
  final AuthRepository _authRepository;
  final EnsureUserNickname _ensureUserNickname;

  LoginBloc(this._signIn, this._authRepository, this._ensureUserNickname)
      : super(LoginInitial()) {
    on<LoginSessionChecked>(_onSessionChecked);
    on<LoginSubmitted>(_onSubmitted);
    on<LoginSocialSubmitted>(_onSocialSubmitted);
  }

  Future<void> _onSessionChecked(
    LoginSessionChecked event,
    Emitter<LoginState> emit,
  ) async {
    emit(LoginLoading());
    // Aguarda a sessão salva ser restaurada e o perfil (onboarding) ser
    // atualizado pela API antes de decidir entre home e quiz. Sem sessão
    // válida (ex.: cadastro aguardando confirmação de e-mail) fica no login.
    final user = await _authRepository.restoreSession();
    if (user != null) {
      emit(LoginSuccess(user: await _ensureUserNickname(user)));
    } else {
      emit(LoginInitial());
    }
  }

  Future<void> _onSubmitted(
    LoginSubmitted event,
    Emitter<LoginState> emit,
  ) async {
    emit(LoginLoading());
    final result = await _signIn(
      SignInParams(email: event.email, password: event.password),
    );
    // Extrai o resultado sem callbacks assíncronos dentro do fold.
    final user = result.fold<User?>((_) => null, (u) => u);
    if (user == null) {
      result.fold(
        (failure) => emit(LoginError(message: _mapFailureMessage(failure))),
        (_) {},
      );
      return;
    }
    emit(LoginSuccess(user: await _ensureUserNickname(user)));
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
    final user = result.fold<User?>((_) => null, (u) => u);
    if (user == null) {
      result.fold(
        (failure) {
          debugPrint('[GoogleBFF] Bloc: falha -> ${failure.runtimeType} | ${failure is KnownFailure ? failure.message : failure}');
          emit(LoginError(message: _mapFailureMessage(failure)));
        },
        (_) {},
      );
      return;
    }
    debugPrint('[GoogleBFF] Bloc: sucesso -> user.id=${user.id}  email=${user.email}');
    emit(LoginSuccess(user: await _ensureUserNickname(user)));
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
