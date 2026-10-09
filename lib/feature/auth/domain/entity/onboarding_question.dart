class OnboardingOption {
  final int id;
  final String label;

  const OnboardingOption({required this.id, required this.label});
}

class OnboardingQuestion {
  final int id;
  final String title;

  /// Curiosidade exibida após o usuário responder ("Você sabia?"). Opcional.
  final String? funFact;
  final List<OnboardingOption> options;

  const OnboardingQuestion({
    required this.id,
    required this.title,
    this.funFact,
    required this.options,
  });
}
