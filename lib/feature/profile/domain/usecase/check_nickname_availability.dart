import 'package:essentials/essentials.dart';

import '../entity/nickname_availability.dart';
import '../nickname_rules.dart';
import '../repository/nickname_repository.dart';

/// Verifica se o apelido digitado ([String] crua, pode começar com "@") está
/// disponível.
///
/// Apelidos que violam as regras locais nem chegam ao servidor: retornam
/// `available = false` com o código da regra.
class CheckNicknameAvailability
    implements UseCase<NicknameAvailability, String> {
  final NicknameRepository _repository;

  CheckNicknameAvailability(this._repository);

  @override
  Future<Try<NicknameAvailability>> call(String params) async {
    final nickname = NicknameRules.normalize(params);
    final localError = NicknameRules.validate(nickname);
    if (localError != null) {
      return Try.success(NicknameAvailability(
        nickname: nickname,
        available: false,
        code: localError,
      ));
    }
    return _repository.checkAvailability(nickname);
  }
}
