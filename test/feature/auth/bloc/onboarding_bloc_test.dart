import 'package:bloc_test/bloc_test.dart';
import 'package:essentials/essentials.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vinum/feature/auth/domain/entity/onboarding_failure_code.dart';
import 'package:vinum/feature/auth/domain/entity/onboarding_question.dart';
import 'package:vinum/feature/auth/domain/entity/onboarding_result.dart';
import 'package:vinum/feature/auth/domain/usecase/get_onboarding_quiz.dart';
import 'package:vinum/feature/auth/domain/usecase/logout.dart';
import 'package:vinum/feature/auth/domain/usecase/submit_onboarding_quiz.dart';
import 'package:vinum/feature/auth/presentation/bloc/onboarding_bloc.dart';
import 'package:vinum/feature/auth/presentation/bloc/onboarding_event.dart';
import 'package:vinum/feature/auth/presentation/bloc/onboarding_state.dart';

class MockGetOnboardingQuiz extends Mock implements GetOnboardingQuiz {}

class MockSubmitOnboardingQuiz extends Mock implements SubmitOnboardingQuiz {}

class MockLogout extends Mock implements Logout {}

const _q1 = OnboardingQuestion(
  id: 1,
  title: 'Pergunta 1',
  funFact: 'Curiosidade 1',
  options: [
    OnboardingOption(id: 10, label: 'A'),
    OnboardingOption(id: 11, label: 'B'),
  ],
);

const _q2 = OnboardingQuestion(
  id: 2,
  title: 'Pergunta 2',
  options: [
    OnboardingOption(id: 20, label: 'C'),
    OnboardingOption(id: 21, label: 'D'),
  ],
);

const _questions = [_q1, _q2];

const _result = OnboardingResult(
  acidityScore: 2.5,
  bodyScore: 1.2,
  preferredType: 'Red',
);

void main() {
  late MockGetOnboardingQuiz mockGetQuiz;
  late MockSubmitOnboardingQuiz mockSubmit;
  late MockLogout mockLogout;

  setUpAll(() {
    registerFallbackValue(
      const SubmitOnboardingQuizParams(selectedOptionIds: []),
    );
  });

  setUp(() {
    mockGetQuiz = MockGetOnboardingQuiz();
    mockSubmit = MockSubmitOnboardingQuiz();
    mockLogout = MockLogout();
  });

  OnboardingBloc buildBloc() =>
      OnboardingBloc(mockGetQuiz, mockSubmit, mockLogout);

  // ─── OnboardingQuizRequested ──────────────────────────────────────────────

  group('OnboardingQuizRequested', () {
    blocTest<OnboardingBloc, OnboardingState>(
      'emite [Loading, Ready] na primeira pergunta',
      build: () {
        when(() => mockGetQuiz(null))
            .thenAnswer((_) async => Try.success(_questions));
        return buildBloc();
      },
      act: (bloc) => bloc.add(OnboardingQuizRequested()),
      expect: () => [
        isA<OnboardingLoading>(),
        isA<OnboardingReady>()
            .having((s) => s.currentIndex, 'currentIndex', 0)
            .having((s) => s.totalQuestions, 'total', 2)
            .having((s) => s.revealedFunFact, 'funFact', isNull),
      ],
    );

    blocTest<OnboardingBloc, OnboardingState>(
      'emite LoadFailure quando o quiz vem vazio',
      build: () {
        when(() => mockGetQuiz(null))
            .thenAnswer((_) async => Try.success(const <OnboardingQuestion>[]));
        return buildBloc();
      },
      act: (bloc) => bloc.add(OnboardingQuizRequested()),
      expect: () => [
        isA<OnboardingLoading>(),
        isA<OnboardingLoadFailure>().having(
          (s) => s.message,
          'message',
          'onboarding_error_empty_quiz',
        ),
      ],
    );

    blocTest<OnboardingBloc, OnboardingState>(
      'mapeia UnknownFailure para erro de conexão',
      build: () {
        when(() => mockGetQuiz(null)).thenAnswer(
          (_) async =>
              Try.reject<List<OnboardingQuestion>>(UnknownFailure('offline')),
        );
        return buildBloc();
      },
      act: (bloc) => bloc.add(OnboardingQuizRequested()),
      expect: () => [
        isA<OnboardingLoading>(),
        isA<OnboardingLoadFailure>().having(
          (s) => s.message,
          'message',
          'onboarding_error_connection',
        ),
      ],
    );
  });

  // ─── Navegação entre perguntas ────────────────────────────────────────────

  group('navegação', () {
    blocTest<OnboardingBloc, OnboardingState>(
      'selecionar revela a curiosidade sem avançar',
      build: buildBloc,
      seed: () => OnboardingReady(questions: _questions),
      act: (bloc) =>
          bloc.add(OnboardingOptionSelected(questionId: 1, optionId: 11)),
      expect: () => [
        isA<OnboardingReady>()
            .having((s) => s.currentIndex, 'currentIndex', 0)
            .having((s) => s.currentSelectedOptionId, 'selected', 11)
            .having((s) => s.revealedFunFact, 'funFact', 'Curiosidade 1')
            .having((s) => s.canGoNext, 'canGoNext', true),
      ],
    );

    blocTest<OnboardingBloc, OnboardingState>(
      'ignora "próxima" sem resposta na pergunta atual',
      build: buildBloc,
      seed: () => OnboardingReady(questions: _questions),
      act: (bloc) => bloc.add(OnboardingNextPressed()),
      expect: () => <OnboardingState>[],
    );

    blocTest<OnboardingBloc, OnboardingState>(
      'avança para a próxima pergunta',
      build: buildBloc,
      seed: () => OnboardingReady(
        questions: _questions,
        selectedOptionIds: const {1: 10},
      ),
      act: (bloc) => bloc.add(OnboardingNextPressed(fromIndex: 0)),
      expect: () => [
        isA<OnboardingReady>()
            .having((s) => s.currentIndex, 'currentIndex', 1)
            .having((s) => s.isLastQuestion, 'isLast', true)
            .having((s) => s.revealedFunFact, 'funFact', isNull),
      ],
    );

    blocTest<OnboardingBloc, OnboardingState>(
      'ignora avanço automático atrasado (fromIndex diferente do atual)',
      build: buildBloc,
      seed: () => OnboardingReady(
        questions: _questions,
        selectedOptionIds: const {1: 10},
        currentIndex: 0,
      ),
      act: (bloc) => bloc.add(OnboardingNextPressed(fromIndex: 1)),
      expect: () => <OnboardingState>[],
    );

    blocTest<OnboardingBloc, OnboardingState>(
      'volta para a pergunta anterior mantendo as respostas',
      build: buildBloc,
      seed: () => OnboardingReady(
        questions: _questions,
        selectedOptionIds: const {1: 10, 2: 21},
        currentIndex: 1,
      ),
      act: (bloc) => bloc.add(OnboardingPreviousPressed()),
      expect: () => [
        isA<OnboardingReady>()
            .having((s) => s.currentIndex, 'currentIndex', 0)
            .having((s) => s.selectedOptionIds, 'selected', {1: 10, 2: 21})
            .having((s) => s.revealedFunFact, 'funFact', 'Curiosidade 1'),
      ],
    );

    blocTest<OnboardingBloc, OnboardingState>(
      'ignora "anterior" na primeira pergunta',
      build: buildBloc,
      seed: () => OnboardingReady(questions: _questions),
      act: (bloc) => bloc.add(OnboardingPreviousPressed()),
      expect: () => <OnboardingState>[],
    );
  });

  // ─── Envio ────────────────────────────────────────────────────────────────

  group('envio', () {
    OnboardingReady answeredOnLast() => OnboardingReady(
          questions: _questions,
          selectedOptionIds: const {2: 21, 1: 10},
          currentIndex: 1,
        );

    blocTest<OnboardingBloc, OnboardingState>(
      '"próxima" na última pergunta envia e emite Completed com o perfil',
      build: () {
        when(() => mockSubmit(any()))
            .thenAnswer((_) async => Try.success(_result));
        return buildBloc();
      },
      seed: answeredOnLast,
      act: (bloc) => bloc.add(OnboardingNextPressed()),
      expect: () => [
        isA<OnboardingReady>().having((s) => s.isSubmitting, 'submitting', true),
        isA<OnboardingCompleted>()
            .having((s) => s.result.preferredType, 'type', 'Red')
            .having((s) => s.result.bodyScore, 'body', 1.2)
            .having((s) => s.result.acidityScore, 'acidity', 2.5),
      ],
      verify: (_) {
        final params = verify(() => mockSubmit(captureAny())).captured.single
            as SubmitOnboardingQuizParams;
        // Na ordem das perguntas, não na ordem de inserção no mapa.
        expect(params.selectedOptionIds, [10, 21]);
      },
    );

    blocTest<OnboardingBloc, OnboardingState>(
      'não envia com perguntas sem resposta',
      build: buildBloc,
      seed: () => OnboardingReady(
        questions: _questions,
        selectedOptionIds: const {1: 10},
      ),
      act: (bloc) => bloc.add(OnboardingSubmitted()),
      expect: () => <OnboardingState>[],
      verify: (_) => verifyNever(() => mockSubmit(any())),
    );

    blocTest<OnboardingBloc, OnboardingState>(
      '401 faz logout e emite SessionExpired',
      build: () {
        when(() => mockSubmit(any())).thenAnswer(
          (_) async => Try.reject<OnboardingResult>(
            KnownFailure(OnboardingFailureCode.unauthorized, null),
          ),
        );
        when(() => mockLogout()).thenAnswer((_) async => Try.success(null));
        return buildBloc();
      },
      seed: answeredOnLast,
      act: (bloc) => bloc.add(OnboardingSubmitted()),
      expect: () => [
        isA<OnboardingReady>().having((s) => s.isSubmitting, 'submitting', true),
        isA<OnboardingSessionExpired>().having(
          (s) => s.message,
          'message',
          'onboarding_error_session_expired',
        ),
      ],
      verify: (_) => verify(() => mockLogout()).called(1),
    );

    blocTest<OnboardingBloc, OnboardingState>(
      'erro de servidor mantém respostas e pergunta atual com erro inline',
      build: () {
        when(() => mockSubmit(any())).thenAnswer(
          (_) async => Try.reject<OnboardingResult>(
            KnownFailure(OnboardingFailureCode.server, null),
          ),
        );
        return buildBloc();
      },
      seed: answeredOnLast,
      act: (bloc) => bloc.add(OnboardingNextPressed()),
      expect: () => [
        isA<OnboardingReady>().having((s) => s.isSubmitting, 'submitting', true),
        isA<OnboardingReady>()
            .having((s) => s.isSubmitting, 'submitting', false)
            .having((s) => s.currentIndex, 'currentIndex', 1)
            .having((s) => s.selectedOptionIds, 'selected', {1: 10, 2: 21})
            .having(
              (s) => s.submitErrorMessage,
              'error',
              'onboarding_error_server',
            ),
      ],
    );
  });
}
