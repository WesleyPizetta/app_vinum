import 'package:essentials/essentials.dart';

import '../../../auth/domain/entity/user.dart';
import '../../../auth/domain/repository/auth_repository.dart';
import '../../../auth/domain/usecase/logout.dart';
import '../../domain/entity/nickname_failure_code.dart';
import '../../domain/nickname_rules.dart';
import '../../domain/usecase/set_my_nickname.dart';
import 'nickname_page_state.dart';

/// Tela "Como você quer ser chamado?": salva o apelido e permite sair da
/// conta (primeiro acesso).
class NicknamePageCubit extends Cubit<NicknamePageState> {
  final SetMyNickname _setMyNickname;
  final Logout _logout;
  final AuthRepository _authRepository;

  NicknamePageCubit(this._setMyNickname, this._logout, this._authRepository)
      : super(NicknamePageIdle());

  User? get currentUser => _authRepository.getCurrentUser();

  Future<void> save(String raw) async {
    final current = state;
    if (current is NicknamePageSaving ||
        current is NicknamePageLoggingOut ||
        current is NicknamePageLoggedOut) {
      return;
    }

    emit(NicknamePageSaving());
    final result = await _setMyNickname(raw);
    if (isClosed) return;

    // Extrai a falha sem callbacks assíncronos dentro do fold.
    final failure = result.fold<Failure?>((f) => f, (_) => null);
    if (failure == null) {
      final nickname = result.getOrElse(() => NicknameRules.normalize(raw));
      emit(NicknamePageSaved(
        nickname: nickname,
        user: _authRepository.getCurrentUser(),
      ));
      return;
    }

    if (failure.code == NicknameFailureCode.unauthorized) {
      await _logout();
      if (isClosed) return;
      emit(NicknamePageLoggedOut(message: 'session_expired'));
      return;
    }

    emit(NicknamePageIdle(
      failureCode: failure.code,
      nickname: NicknameRules.normalize(raw),
    ));
  }

  Future<void> logout() async {
    final current = state;
    if (current is NicknamePageSaving ||
        current is NicknamePageLoggingOut ||
        current is NicknamePageLoggedOut) {
      return;
    }
    emit(NicknamePageLoggingOut());
    // O logout limpa a sessão local mesmo se a chamada à API falhar.
    await _logout();
    if (isClosed) return;
    emit(NicknamePageLoggedOut());
  }
}
