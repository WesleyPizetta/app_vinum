sealed class OnboardingEvent {}

/// Carrega (ou recarrega, no "tentar novamente") o quiz.
class OnboardingQuizRequested extends OnboardingEvent {}

/// Seleciona (ou troca) a resposta de uma pergunta. Não avança sozinho: a UI
/// decide se avança automaticamente (pergunta sem curiosidade) ou mostra o
/// "Você sabia?" e espera [OnboardingNextPressed].
class OnboardingOptionSelected extends OnboardingEvent {
  final int questionId;
  final int optionId;

  OnboardingOptionSelected({required this.questionId, required this.optionId});
}

/// Avança para a próxima pergunta; na última, envia as respostas.
///
/// [fromIndex], quando informado, faz o evento ser ignorado se a pergunta
/// atual já não for mais essa (ex.: avanço automático disparado com atraso
/// depois que o usuário já tocou em "Próxima" ou "Anterior").
class OnboardingNextPressed extends OnboardingEvent {
  final int? fromIndex;

  OnboardingNextPressed({this.fromIndex});
}

/// Volta para a pergunta anterior (mantendo as respostas já dadas).
class OnboardingPreviousPressed extends OnboardingEvent {}

/// Envia as respostas (exige todas as perguntas respondidas).
class OnboardingSubmitted extends OnboardingEvent {}
