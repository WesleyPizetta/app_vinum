/// Códigos de falha do feature de vinhos (usados em `KnownFailure.code`).
class WineFailureCode {
  WineFailureCode._();

  static const String notFound = 'WINE_NOT_FOUND';
  static const String server = 'WINE_SERVER_ERROR';
  static const String invalidResponse = 'WINE_INVALID_RESPONSE';
  static const String requestFailed = 'WINE_REQUEST_FAILED';
}
