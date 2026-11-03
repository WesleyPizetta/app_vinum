import '../../domain/entity/onboarding_question.dart';
import '../../domain/entity/onboarding_result.dart';

sealed class OnboardingState {}

class OnboardingLoading extends OnboardingState {}

/// Falha ao carregar o quiz (inclui quiz vazio). A UI oferece "tentar
/// novamente", que dispara [OnboardingQuizRequested].
class OnboardingLoadFailure extends OnboardingState {
  final String message;
  OnboardingLoadFailure({required this.message});
}

/// Quiz carregado, exibido uma pergunta por vez ([currentIndex]). Mantém as
/// seleções durante e após falhas de envio.
class OnboardingReady extends OnboardingState {
  final List<OnboardingQuestion> questions;

  /// questionId -> optionId selecionado.
  final Map<int, int> selectedOptionIds;

  /// Índice (em [questions]) da pergunta exibida.
  final int currentIndex;
  final bool isSubmitting;

  /// Chave i18n do erro do último envio, exibida inline.
  final String? submitErrorMessage;

  OnboardingReady({
    required this.questions,
    Map<int, int> selectedOptionIds = const {},
    int currentIndex = 0,
    this.isSubmitting = false,
    this.submitErrorMessage,
  })  : selectedOptionIds = Map<int, int>.unmodifiable(selectedOptionIds),
        currentIndex = questions.isEmpty
            ? 0
            : currentIndex.clamp(0, questions.length - 1).toInt();

  int get totalQuestions => questions.length;

  OnboardingQuestion get currentQuestion => questions[currentIndex];

  bool get isFirstQuestion => currentIndex == 0;

  bool get isLastQuestion => currentIndex == questions.length - 1;

  /// Opção escolhida na pergunta atual, se houver.
  int? get currentSelectedOptionId => selectedOptionIds[currentQuestion.id];

  bool get isCurrentAnswered => currentSelectedOptionId != null;

  /// Curiosidade da pergunta atual, revelada só depois de respondida.
  String? get revealedFunFact =>
      isCurrentAnswered ? currentQuestion.funFact : null;

  /// Pode avançar (ou enviar, na última pergunta).
  bool get canGoNext =>
      isCurrentAnswered && !isSubmitting && (!isLastQuestion || isComplete);

  bool get canGoPrevious => !isFirstQuestion && !isSubmitting;

  bool get isComplete =>
      questions.isNotEmpty &&
      questions.every((q) => selectedOptionIds.containsKey(q.id));

  bool get canSubmit => isComplete && !isSubmitting;

  int get answeredCount =>
      questions.where((q) => selectedOptionIds.containsKey(q.id)).length;

  /// Ids das opções na ordem das perguntas (uma por pergunta).
  List<int> get orderedSelectedOptionIds => questions
      .map((q) => selectedOptionIds[q.id])
      .whereType<int>()
      .toList(growable: false);

  OnboardingReady copyWith({
    Map<int, int>? selectedOptionIds,
    int? currentIndex,
    bool? isSubmitting,
    String? submitErrorMessage,
    bool clearSubmitError = false,
  }) {
    return OnboardingReady(
      questions: questions,
      selectedOptionIds: selectedOptionIds ?? this.selectedOptionIds,
      currentIndex: currentIndex ?? this.currentIndex,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submitErrorMessage: clearSubmitError
          ? null
          : (submitErrorMessage ?? this.submitErrorMessage),
    );
  }
}

/// Envio concluído e usuário local marcado como onboarding concluído. A UI
/// mostra o perfil de gosto ([result]) antes de seguir.
class OnboardingCompleted extends OnboardingState {
  final OnboardingResult result;
  OnboardingCompleted({required this.result});
}

/// Sessão expirada (401) no envio: logout já executado, voltar ao login.
class OnboardingSessionExpired extends OnboardingState {
  final String message;
  OnboardingSessionExpired({required this.message});
}
