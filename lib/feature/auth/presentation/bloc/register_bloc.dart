import 'package:essentials/essentials.dart';

import '../../../profile/domain/nickname_rules.dart';
import '../../../profile/presentation/widget/nickname_messages.dart';
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
    // A disponibilidade já foi confirmada pela tela; aqui só garante as
    // regras locais antes de criar a conta.
    final nickname = NicknameRules.normalize(event.nickname);
    final nicknameError = NicknameRules.validate(nickname);
    if (nicknameError != null) {
      emit(RegisterError(message: nicknameMessageKey(nicknameError)));
      return;
    }

    emit(RegisterLoading());
    final result = await _signUp(
      SignUpParams(
        name: event.name,
        email: event.email,
        password: event.password,
        nickname: nickname,
      ),
    );
    result.fold(
      (failure) => emit(RegisterError(message: _mapFailureMessage(failure))),
      (result) => emit(RegisterSuccess(
        user: result.user,
        requiresEmailConfirmation: result.requiresEmailConfirmation,
      )),
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
