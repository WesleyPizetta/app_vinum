/// Códigos usados em [KnownFailure.code] pelas operações de apelido
/// (`/v1/nicknames/check` e `/v1/me/nickname`).
///
/// Os códigos `NICKNAME_*` de regra são os mesmos devolvidos pelo BFF; os
/// demais são gerados pelo app para falhas de transporte/HTTP.
class NicknameFailureCode {
  NicknameFailureCode._();

  // ── Regras (mesmos códigos do BFF) ──
  static const String required = 'NICKNAME_REQUIRED';
  static const String tooShort = 'NICKNAME_TOO_SHORT';
  static const String tooLong = 'NICKNAME_TOO_LONG';
  static const String invalidChars = 'NICKNAME_INVALID_CHARS';
  static const String invalidFormat = 'NICKNAME_INVALID_FORMAT';
  static const String reserved = 'NICKNAME_RESERVED';
  static const String offensive = 'NICKNAME_OFFENSIVE';
  static const String taken = 'NICKNAME_TAKEN';

  // ── Gerados pelo app ──

  /// Sem conexão / exceção de transporte.
  static const String network = 'NICKNAME_NETWORK_ERROR';

  /// 401 — token ausente, inválido ou expirado.
  static const String unauthorized = 'NICKNAME_UNAUTHORIZED';

  /// 400 — corpo inválido.
  static const String badRequest = 'NICKNAME_BAD_REQUEST';

  /// 5xx — erro no servidor.
  static const String server = 'NICKNAME_SERVER_ERROR';

  /// Qualquer outro status HTTP de erro.
  static const String requestFailed = 'NICKNAME_REQUEST_FAILED';

  /// Resposta 2xx com corpo fora do contrato esperado.
  static const String invalidResponse = 'NICKNAME_INVALID_RESPONSE';

  static const Set<String> ruleCodes = {
    required,
    tooShort,
    tooLong,
    invalidChars,
    invalidFormat,
    reserved,
    offensive,
    taken,
  };

  /// `true` quando [code] é uma violação de regra do apelido (o apelido em
  /// si não pode ser usado), e não uma falha de rede/servidor.
  static bool isRuleViolation(String? code) =>
      code != null && ruleCodes.contains(code);
}
