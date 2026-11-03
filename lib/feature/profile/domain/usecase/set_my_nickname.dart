import 'package:essentials/essentials.dart';

import '../../../auth/domain/repository/auth_repository.dart';
import '../nickname_rules.dart';
import '../repository/nickname_repository.dart';

/// Salva o apelido do usuário autenticado ([String] crua, pode começar com
/// "@") e, em caso de sucesso, atualiza o usuário em cache/sessão para que o
/// resto do app veja o novo apelido.
///
/// Retorna o apelido salvo. Violação de regra local: [KnownFailure] com o
/// código da regra, sem chamar o servidor.
class SetMyNickname implements UseCase<String, String> {
  final NicknameRepository _repository;
  final AuthRepository _authRepository;

  SetMyNickname(this._repository, this._authRepository);

  @override
  Future<Try<String>> call(String params) async {
    final nickname = NicknameRules.normalize(params);
    final localError = NicknameRules.validate(nickname);
    if (localError != null) {
      return Try.reject(KnownFailure(localError, null));
    }

    final result = await _repository.setMyNickname(nickname);
    final saved = result.fold<String?>((_) => null, (value) => value);
    if (saved != null) {
      await _authRepository.updateCurrentUserNickname(saved);
    }
    return result;
  }
}
