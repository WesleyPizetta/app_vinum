import 'package:essentials/essentials.dart';

import '../../domain/entity/onboarding_failure_code.dart';
import '../../domain/entity/onboarding_result.dart';
import '../../domain/usecase/get_onboarding_quiz.dart';
import '../../domain/usecase/logout.dart';
import '../../domain/usecase/submit_onboarding_quiz.dart';
import 'onboarding_event.dart';
import 'onboarding_state.dart';

class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  final GetOnboardingQuiz _getOnboardingQuiz;
  final SubmitOnboardingQuiz _submitOnboardingQuiz;
  final Logout _logout;

  OnboardingBloc(
    this._getOnboardingQuiz,
    this._submitOnboardingQuiz,
    this._logout,
  ) : super(OnboardingLoading()) {
    on<OnboardingQuizRequested>(_onQuizRequested);
    on<OnboardingOptionSelected>(_onOptionSelected);
    on<OnboardingNextPressed>(_onNextPressed);
    on<OnboardingPreviousPressed>(_onPreviousPressed);
    on<OnboardingSubmitted>(_onSubmitted);
  }

  Future<void> _onQuizRequested(
    OnboardingQuizRequested event,
    Emitter<OnboardingState> emit,
  ) async {
    emit(OnboardingLoading());
    final result = await _getOnboardingQuiz(null);

    result.fold(
      (failure) => emit(
        OnboardingLoadFailure(message: _mapLoadFailure(failure)),
      ),
      (questions) {
        if (questions.isEmpty) {
          emit(OnboardingLoadFailure(message: 'onboarding_error_empty_quiz'));
        } else {
          emit(OnboardingReady(questions: questions));
        }
      },
    );
  }

  void _onOptionSelected(
    OnboardingOptionSelected event,
    Emitter<OnboardingState> emit,
  ) {
    final current = state;
    if (current is! OnboardingReady || current.isSubmitting) return;

    final updated = Map<int, int>.of(current.selectedOptionIds)
      ..[event.questionId] = event.optionId;
    emit(current.copyWith(
      selectedOptionIds: updated,
      clearSubmitError: true,
    ));
  }

  Future<void> _onNextPressed(
    OnboardingNextPressed event,
    Emitter<OnboardingState> emit,
  ) async {
    final current = state;
    if (current is! OnboardingReady || !current.canGoNext) return;
    final fromIndex = event.fromIndex;
    if (fromIndex != null && fromIndex != current.currentIndex) return;

    if (current.isLastQuestion) {
      await _submit(current, emit);
      return;
    }
    emit(current.copyWith(
      currentIndex: current.currentIndex + 1,
      clearSubmitError: true,
    ));
  }

  void _onPreviousPressed(
    OnboardingPreviousPressed event,
    Emitter<OnboardingState> emit,
  ) {
    final current = state;
    if (current is! OnboardingReady || !current.canGoPrevious) return;

    emit(current.copyWith(
      currentIndex: current.currentIndex - 1,
      clearSubmitError: true,
    ));
  }

  Future<void> _onSubmitted(
    OnboardingSubmitted event,
    Emitter<OnboardingState> emit,
  ) async {
    final current = state;
    if (current is! OnboardingReady) return;
    await _submit(current, emit);
  }

  Future<void> _submit(
    OnboardingReady current,
    Emitter<OnboardingState> emit,
  ) async {
    if (!current.canSubmit) return;

    emit(current.copyWith(isSubmitting: true, clearSubmitError: true));

    final result = await _submitOnboardingQuiz(
      SubmitOnboardingQuizParams(
        selectedOptionIds: current.orderedSelectedOptionIds,
      ),
    );

    // Extrai resultado/falha sem callbacks assíncronos dentro do fold.
    final profile = result.fold<OnboardingResult?>((_) => null, (r) => r);
    if (profile != null) {
      emit(OnboardingCompleted(result: profile));
      return;
    }
    final failure = result.fold<Failure>(
      (f) => f,
      (_) => UnknownFailure(null),
    );

    if (_isUnauthorized(failure)) {
      await _logout();
      emit(OnboardingSessionExpired(
        message: 'onboarding_error_session_expired',
      ));
      return;
    }

    // Mantém as seleções para permitir reenviar.
    emit(current.copyWith(
      isSubmitting: false,
      submitErrorMessage: _mapSubmitFailure(failure),
    ));
  }

  bool _isUnauthorized(Failure failure) =>
      failure is KnownFailure &&
      failure.code == OnboardingFailureCode.unauthorized;

  String _mapLoadFailure(Failure failure) {
    if (failure is KnownFailure) {
      switch (failure.code) {
        case OnboardingFailureCode.server:
          return 'onboarding_error_server';
        case OnboardingFailureCode.invalidResponse:
          return 'onboarding_error_invalid_response';
      }
      return 'onboarding_error_load';
    }
    // UnknownFailure: exceção na chamada HTTP (tipicamente conectividade).
    return 'onboarding_error_connection';
  }

  String _mapSubmitFailure(Failure failure) {
    if (failure is KnownFailure) {
      switch (failure.code) {
        case OnboardingFailureCode.invalidAnswers:
          return 'onboarding_error_invalid_answers';
        case OnboardingFailureCode.server:
          return 'onboarding_error_server';
      }
      return 'onboarding_error_submit';
    }
    return 'onboarding_error_connection';
  }
}
