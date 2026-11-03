import 'package:essentials/essentials.dart';

import '../entity/onboarding_result.dart';
import '../repository/auth_repository.dart';

class SubmitOnboardingQuizParams {
  final List<int> selectedOptionIds;

  const SubmitOnboardingQuizParams({required this.selectedOptionIds});
}

/// Envia as respostas do quiz e, em caso de sucesso, garante que o usuário
/// local fique marcado como onboarding concluído — mesmo que a atualização do
/// perfil (`/v1/me/profile`) falhe — para evitar voltar ao onboarding.
class SubmitOnboardingQuiz
    implements UseCase<OnboardingResult, SubmitOnboardingQuizParams> {
  static const Duration _profileRefreshTimeout = Duration(seconds: 10);

  final AuthRepository _repository;

  SubmitOnboardingQuiz(this._repository);

  @override
  Future<Try<OnboardingResult>> call(SubmitOnboardingQuizParams params) async {
    final result = await _repository.submitOnboardingQuiz(
      selectedOptionIds: params.selectedOptionIds,
    );
    if (result.isLeft()) return result;

    // Best-effort: o refresh já ignora falhas; o timeout evita travar a UI.
    try {
      await _repository
          .refreshCurrentUserProfile()
          .timeout(_profileRefreshTimeout);
    } catch (_) {
      // Ignorado de propósito: a marcação local abaixo é o que importa.
    }

    // Feito por último para que um perfil desatualizado não sobrescreva a flag.
    await _repository.markOnboardingCompleted();
    return result;
  }
}
