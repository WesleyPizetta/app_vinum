import '../../../profile/domain/nickname_rules.dart';
import '../../../profile/domain/usecase/set_my_nickname.dart';
import '../entity/user.dart';
import '../repository/auth_repository.dart';

/// Primeiro acesso de quem escolheu o apelido no cadastro: se o perfil ainda
/// não tem apelido mas os metadados do Supabase têm (`nickname`, gravado no
/// sign-up), salva-o silenciosamente via [SetMyNickname].
///
/// Nunca falha: em qualquer erro devolve [user] como veio (sem apelido), e o
/// app mostra a tela de apelido (ver `PostAuthDestination`).
class EnsureUserNickname {
  static const Duration _timeout = Duration(seconds: 10);

  final AuthRepository _authRepository;
  final SetMyNickname _setMyNickname;

  EnsureUserNickname(this._authRepository, this._setMyNickname);

  Future<User> call(User user) async {
    if (user.hasNickname) return user;

    final pending = _authRepository.getSignUpNickname();
    if (pending == null || !NicknameRules.isValid(pending)) return user;

    try {
      final result = await _setMyNickname(pending).timeout(_timeout);
      final saved = result.fold<String?>((_) => null, (value) => value);
      if (saved == null) return user;
      final current = _authRepository.getCurrentUser();
      if (current != null && current.id == user.id && current.hasNickname) {
        return current;
      }
      return user.copyWith(nickname: saved);
    } catch (_) {
      // Timeout/erro inesperado: segue para a tela de apelido.
      return user;
    }
  }
}
