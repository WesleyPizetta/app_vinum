import 'package:essentials/essentials.dart';

import '../entity/onboarding_question.dart';
import '../entity/onboarding_result.dart';
import '../entity/sign_up_result.dart';
import '../entity/user.dart';

abstract class AuthRepository {
  Future<Try<User>> signIn({
    required String email,
    required String password,
  });

  Future<Try<User>> signInWithSocial({
    required String provider,
    required String idToken,
    String? nonce,
  });

  /// Cria a conta. Se o projeto exigir confirmação de e-mail, retorna
  /// `requiresEmailConfirmation = true` e NÃO inicia sessão.
  ///
  /// [nickname] (já normalizado) vai nos metadados do usuário (`nickname`)
  /// e é aplicado no primeiro acesso (ver [getSignUpNickname]).
  Future<Try<SignUpResult>> signUp({
    required String email,
    required String password,
    required String name,
    String? nickname,
  });

  Future<Try<void>> refreshSession();

  /// Atualiza o usuário local com os dados de `/v1/me/profile`.
  /// Falhas são ignoradas (best-effort).
  Future<void> refreshCurrentUserProfile();

  Future<Try<List<OnboardingQuestion>>> getOnboardingQuiz();

  Future<Try<OnboardingResult>> submitOnboardingQuiz({
    required List<int> selectedOptionIds,
  });

  /// Marca o usuário local como `onboardingCompleted = true` e persiste a
  /// sessão no armazenamento seguro. Retorna o usuário atualizado, ou `null`
  /// se não houver usuário autenticado.
  Future<User?> markOnboardingCompleted();

  /// Atualiza o apelido do usuário local e persiste a sessão. Retorna o
  /// usuário atualizado, ou `null` se não houver usuário autenticado.
  Future<User?> updateCurrentUserNickname(String nickname);

  /// Apelido escolhido no cadastro, salvo nos metadados do usuário do
  /// Supabase (`user_metadata.nickname`). `null` se não houver.
  String? getSignUpNickname();

  Future<Try<void>> logout();

  /// Aguarda a restauração da sessão salva no aparelho e, havendo token,
  /// atualiza o usuário com `/v1/me/profile` (inclui `onboarding_completed`).
  /// Retorna o usuário somente se existir uma sessão válida (com token).
  /// Deve ser usado na abertura do app, antes de decidir a rota inicial.
  Future<User?> restoreSession();

  User? getCurrentUser();

  String? getAccessToken();
}
