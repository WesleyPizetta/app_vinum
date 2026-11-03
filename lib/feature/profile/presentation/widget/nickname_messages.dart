import '../../domain/entity/nickname_failure_code.dart';

/// Chave i18n da mensagem para um código de `NicknameFailureCode`.
String nicknameMessageKey(String? code) {
  switch (code) {
    case NicknameFailureCode.required:
      return 'nickname_error_required';
    case NicknameFailureCode.tooShort:
      return 'nickname_error_too_short';
    case NicknameFailureCode.tooLong:
      return 'nickname_error_too_long';
    case NicknameFailureCode.invalidChars:
      return 'nickname_error_invalid_chars';
    case NicknameFailureCode.invalidFormat:
      return 'nickname_error_invalid_format';
    case NicknameFailureCode.reserved:
      return 'nickname_error_reserved';
    case NicknameFailureCode.offensive:
      return 'nickname_error_offensive';
    case NicknameFailureCode.taken:
      return 'nickname_error_taken';
    case NicknameFailureCode.network:
      return 'nickname_error_connection';
    case NicknameFailureCode.server:
      return 'nickname_error_server';
    case NicknameFailureCode.unauthorized:
      return 'session_expired';
    default:
      return 'nickname_error_generic';
  }
}
