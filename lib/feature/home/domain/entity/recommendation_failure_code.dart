/// Códigos usados em [KnownFailure.code] pela API `/v1/me/*` de
/// recomendações (`/me/recommendations`, `/me/search`,
/// `/me/wines/{id}/match`).
///
/// A camada de dados traduz o status HTTP (e o `code` do corpo) para um
/// destes códigos e a apresentação decide o estado da seção.
class RecommendationFailureCode {
  RecommendationFailureCode._();

  /// 409 `ONBOARDING_REQUIRED` — usuário ainda não tem perfil de gosto.
  static const String onboardingRequired = 'ONBOARDING_REQUIRED';

  /// 401 — token ausente, inválido ou expirado.
  static const String unauthorized = 'RECOMMENDATIONS_UNAUTHORIZED';

  /// 404 — recurso não encontrado (ex.: vinho inexistente em
  /// `GET /v1/me/wines/{id}/match`).
  static const String notFound = 'RECOMMENDATIONS_NOT_FOUND';

  /// 400 — parâmetro inválido (ex.: `food` fora da lista aceita, ou `q` da
  /// busca com menos de 2 letras).
  static const String badRequest = 'RECOMMENDATIONS_BAD_REQUEST';

  /// 5xx — erro no servidor.
  static const String server = 'RECOMMENDATIONS_SERVER_ERROR';

  /// Qualquer outro status HTTP de erro.
  static const String requestFailed = 'RECOMMENDATIONS_REQUEST_FAILED';

  /// Resposta 2xx com corpo fora do contrato esperado.
  static const String invalidResponse = 'RECOMMENDATIONS_INVALID_RESPONSE';
}
