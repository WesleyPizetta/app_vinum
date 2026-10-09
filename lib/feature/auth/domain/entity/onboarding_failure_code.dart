/// Códigos usados em [KnownFailure.code] pelas operações de onboarding.
///
/// A camada de dados traduz o status HTTP para um destes códigos e a camada
/// de apresentação traduz o código para uma chave de string i18n.
class OnboardingFailureCode {
  OnboardingFailureCode._();

  /// 400 — respostas inválidas ou incompletas.
  static const String invalidAnswers = 'ONBOARDING_INVALID_ANSWERS';

  /// 401 — token ausente, inválido ou expirado.
  static const String unauthorized = 'ONBOARDING_UNAUTHORIZED';

  /// 5xx — erro no servidor.
  static const String server = 'ONBOARDING_SERVER_ERROR';

  /// Qualquer outro status HTTP de erro.
  static const String requestFailed = 'ONBOARDING_REQUEST_FAILED';

  /// Resposta 2xx com corpo fora do contrato esperado.
  static const String invalidResponse = 'ONBOARDING_INVALID_RESPONSE';
}
