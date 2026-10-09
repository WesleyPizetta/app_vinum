/// Códigos usados em [KnownFailure.code] pelos endpoints de favoritos
/// (`/v1/me/favorites...`).
class FavoriteFailureCode {
  FavoriteFailureCode._();

  /// 401 — token ausente, inválido ou expirado.
  static const String unauthorized = 'FAVORITES_UNAUTHORIZED';

  /// 404 — o vinho não existe (PUT).
  static const String notFound = 'FAVORITES_WINE_NOT_FOUND';

  /// 400 — `wine_id` inválido.
  static const String badRequest = 'FAVORITES_BAD_REQUEST';

  /// 5xx — erro no servidor.
  static const String server = 'FAVORITES_SERVER_ERROR';

  /// Qualquer outro status HTTP de erro.
  static const String requestFailed = 'FAVORITES_REQUEST_FAILED';

  /// Resposta 2xx com corpo fora do contrato esperado.
  static const String invalidResponse = 'FAVORITES_INVALID_RESPONSE';
}
