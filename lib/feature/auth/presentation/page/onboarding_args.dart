/// Argumentos de rota de `ApplicationRoute.onboarding`.
///
/// Sem argumentos (fluxo de primeiro acesso), o botão final substitui a pilha
/// pela home. Com [retake] = `true` (aberto de dentro do app para refazer o
/// quiz), a página pode ser fechada com "X" e, ao final, faz
/// `Navigator.pop(context, true)` para quem abriu recarregar o que depende do
/// perfil de gosto.
class OnboardingArgs {
  final bool retake;

  const OnboardingArgs({this.retake = false});
}
