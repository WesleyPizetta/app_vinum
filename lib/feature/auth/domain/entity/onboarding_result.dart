/// Perfil de sabor calculado pelo backend após o envio do quiz de onboarding.
class OnboardingResult {
  final double acidityScore;
  final double bodyScore;
  final String? preferredType;

  const OnboardingResult({
    required this.acidityScore,
    required this.bodyScore,
    this.preferredType,
  });
}
