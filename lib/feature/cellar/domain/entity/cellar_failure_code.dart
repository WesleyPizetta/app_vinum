/// Códigos usados em [KnownFailure.code] por `GET /v1/me/reviews`.
class CellarFailureCode {
  CellarFailureCode._();

  /// 401 — token ausente, inválido ou expirado.
  static const String unauthorized = 'CELLAR_UNAUTHORIZED';

  /// 400 — parâmetros de paginação inválidos.
  static const String badRequest = 'CELLAR_BAD_REQUEST';

  /// 5xx — erro no servidor.
  static const String server = 'CELLAR_SERVER_ERROR';

  /// Qualquer outro status HTTP de erro.
  static const String requestFailed = 'CELLAR_REQUEST_FAILED';

  /// Resposta 2xx com corpo fora do contrato esperado.
  static const String invalidResponse = 'CELLAR_INVALID_RESPONSE';
}
