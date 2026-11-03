import 'user.dart';

/// Para onde o usuário vai depois de entrar (login, login social ou sessão
/// restaurada na abertura do app).
///
/// Ordem do primeiro acesso: apelido → quiz de onboarding → home.
enum PostAuthDestination {
  /// Ainda sem apelido: tela "Como você quer ser chamado?".
  nickname,

  /// Quiz de paladar ainda não respondido.
  onboarding,

  home;

  static PostAuthDestination forUser(User user) {
    if (!user.hasNickname) return PostAuthDestination.nickname;
    return user.onboardingCompleted
        ? PostAuthDestination.home
        : PostAuthDestination.onboarding;
  }
}
