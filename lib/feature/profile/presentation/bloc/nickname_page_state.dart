import '../../../auth/domain/entity/user.dart';

sealed class NicknamePageState {}

/// Editando. Após uma falha ao salvar, [failureCode] traz o código de
/// `NicknameFailureCode` e [nickname] o apelido (normalizado) recusado.
class NicknamePageIdle extends NicknamePageState {
  final String? failureCode;
  final String? nickname;

  NicknamePageIdle({this.failureCode, this.nickname});
}

class NicknamePageSaving extends NicknamePageState {}

class NicknamePageSaved extends NicknamePageState {
  final String nickname;

  /// Usuário atualizado (com o novo apelido), para seguir o fluxo.
  final User? user;

  NicknamePageSaved({required this.nickname, this.user});
}

class NicknamePageLoggingOut extends NicknamePageState {}

/// Sessão encerrada (pelo botão "Sair" ou por 401 ao salvar).
class NicknamePageLoggedOut extends NicknamePageState {
  /// Chave i18n a mostrar (ex.: `session_expired`), ou `null`.
  final String? message;

  NicknamePageLoggedOut({this.message});
}
