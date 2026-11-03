import 'package:essentials/essentials.dart';

import '../entity/nickname_availability.dart';

abstract class NicknameRepository {
  /// `GET /v1/nicknames/check`. [nickname] já normalizado. Com usuário
  /// autenticado, o apelido atual dele conta como disponível.
  ///
  /// Falhas: [KnownFailure] com código de `NicknameFailureCode`.
  Future<Try<NicknameAvailability>> checkAvailability(String nickname);

  /// `PUT /v1/me/nickname`. Retorna o apelido salvo (normalizado pelo
  /// servidor). Falhas: [KnownFailure] com o `NICKNAME_*` do servidor (409 /
  /// 422) ou um código de transporte de `NicknameFailureCode`.
  Future<Try<String>> setMyNickname(String nickname);
}
