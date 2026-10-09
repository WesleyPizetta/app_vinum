import 'dart:async';

import 'package:essentials/essentials.dart';
import 'package:flutter/material.dart';

import '../../../../core/navigation/application_route.dart';
import '../../domain/entity/onboarding_question.dart';
import '../bloc/onboarding_bloc.dart';
import '../bloc/onboarding_event.dart';
import '../bloc/onboarding_state.dart';
import '../widget/onboarding_quiz_widgets.dart';
import '../widget/onboarding_result_view.dart';
import 'onboarding_args.dart';

/// Quiz de paladar gamificado (uma pergunta por tela) seguido do resultado
/// "Seu perfil de gosto".
///
/// Aceita [OnboardingArgs] via construtor ou `RouteSettings.arguments`.
class OnboardingPage extends StatelessWidget {
  /// Quando nulo, usa `ModalRoute.settings.arguments` (se for
  /// [OnboardingArgs]) ou o fluxo padrão de primeiro acesso.
  final OnboardingArgs? args;

  const OnboardingPage({super.key, this.args});

  OnboardingArgs _resolveArgs(BuildContext context) {
    final explicit = args;
    if (explicit != null) return explicit;
    final routeArgs = ModalRoute.of(context)?.settings.arguments;
    return routeArgs is OnboardingArgs ? routeArgs : const OnboardingArgs();
  }

  @override
  Widget build(BuildContext context) {
    final resolvedArgs = _resolveArgs(context);

    return BlocProvider(
      create: (_) => ApplicationContainer.resolve<OnboardingBloc>()
        ..add(OnboardingQuizRequested()),
      child: _OnboardingView(retake: resolvedArgs.retake),
    );
  }
}

class _OnboardingView extends StatelessWidget {
  final bool retake;

  const _OnboardingView({required this.retake});

  /// Ação final da tela de resultado.
  void _finish(BuildContext context) {
    if (retake) {
      Navigator.pop(context, true);
    } else {
      Navigator.pushNamedAndRemoveUntil(
        context,
        ApplicationRoute.home,
        (_) => false,
      );
    }
  }

  /// "X" do modo refazer. Depois do envio o perfil já mudou, então devolve
  /// `true` para quem abriu recarregar.
  void _close(BuildContext context, OnboardingState state) {
    Navigator.pop(context, state is OnboardingCompleted ? true : null);
  }

  bool _canPop(OnboardingState state) => switch (state) {
        OnboardingReady(:final isFirstQuestion, :final isSubmitting) =>
          isFirstQuestion && !isSubmitting,
        OnboardingLoading() || OnboardingLoadFailure() => true,
        OnboardingCompleted() || OnboardingSessionExpired() => false,
      };

  /// Voltar do sistema quando [_canPop] é falso.
  void _onBlockedPop(BuildContext context, OnboardingState state) {
    if (state is OnboardingReady && state.canGoPrevious) {
      context.read<OnboardingBloc>().add(OnboardingPreviousPressed());
    } else if (state is OnboardingCompleted) {
      _finish(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<OnboardingBloc, OnboardingState>(
      listenWhen: (previous, current) => current is OnboardingSessionExpired,
      listener: (context, state) {
        if (state is OnboardingSessionExpired) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(getString(context, state.message))),
          );
          Navigator.pushNamedAndRemoveUntil(
            context,
            ApplicationRoute.login,
            (_) => false,
          );
        }
      },
      child: BlocBuilder<OnboardingBloc, OnboardingState>(
        builder: (context, state) {
          final isSubmitting = state is OnboardingReady && state.isSubmitting;

          return PopScope(
            canPop: _canPop(state),
            onPopInvokedWithResult: (didPop, _) {
              if (didPop) return;
              _onBlockedPop(context, state);
            },
            child: Scaffold(
              appBar: VinumAppBar(
                title: getString(context, 'onboarding_title'),
                showBackButton: false,
                actions: retake
                    ? [
                        IconButton(
                          icon: const Icon(Icons.close),
                          tooltip: getString(context, 'onboarding_close'),
                          onPressed: isSubmitting
                              ? null
                              : () => _close(context, state),
                        ),
                      ]
                    : null,
              ),
              body: SafeArea(
                child: switch (state) {
                  OnboardingLoadFailure(:final message) => VinumErrorWidget(
                      message: getString(context, message),
                      onRetry: () => context
                          .read<OnboardingBloc>()
                          .add(OnboardingQuizRequested()),
                    ),
                  final OnboardingReady ready =>
                    _OnboardingQuizView(state: ready),
                  OnboardingCompleted(:final result) => OnboardingResultView(
                      result: result,
                      actionLabel: getString(
                        context,
                        retake
                            ? 'onboarding_result_done'
                            : 'onboarding_result_start',
                      ),
                      onAction: () => _finish(context),
                    ),
                  OnboardingLoading() ||
                  OnboardingSessionExpired() =>
                    const LoadingWidget(),
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class _OnboardingQuizView extends StatefulWidget {
  final OnboardingReady state;

  const _OnboardingQuizView({required this.state});

  @override
  State<_OnboardingQuizView> createState() => _OnboardingQuizViewState();
}

class _OnboardingQuizViewState extends State<_OnboardingQuizView> {
  /// Atraso do avanço automático em perguntas sem curiosidade, para o
  /// usuário ver a opção marcada antes de trocar de tela.
  static const Duration _autoAdvanceDelay = Duration(milliseconds: 700);

  Timer? _autoAdvanceTimer;

  @override
  void dispose() {
    _autoAdvanceTimer?.cancel();
    super.dispose();
  }

  void _onOptionTap(OnboardingQuestion question, int optionId) {
    final state = widget.state;
    final bloc = context.read<OnboardingBloc>();
    bloc.add(
      OnboardingOptionSelected(questionId: question.id, optionId: optionId),
    );

    _autoAdvanceTimer?.cancel();
    // Com curiosidade, o usuário lê o "Você sabia?" e avança no botão. Na
    // última pergunta o envio é sempre explícito ("Ver meu perfil").
    if (question.funFact == null && !state.isLastQuestion) {
      final fromIndex = state.currentIndex;
      _autoAdvanceTimer = Timer(_autoAdvanceDelay, () {
        if (!mounted) return;
        bloc.add(OnboardingNextPressed(fromIndex: fromIndex));
      });
    }
  }

  void _onNext() {
    _autoAdvanceTimer?.cancel();
    context.read<OnboardingBloc>().add(OnboardingNextPressed());
  }

  void _onPrevious() {
    _autoAdvanceTimer?.cancel();
    context.read<OnboardingBloc>().add(OnboardingPreviousPressed());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = widget.state;
    final question = state.currentQuestion;
    final submitError = state.submitErrorMessage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Dimens.spacing24,
            Dimens.spacing16,
            Dimens.spacing24,
            0,
          ),
          child: OnboardingProgressHeader(
            current: state.currentIndex + 1,
            total: state.totalQuestions,
          ),
        ),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            layoutBuilder: (currentChild, previousChildren) => Stack(
              fit: StackFit.expand,
              children: [
                ...previousChildren,
                if (currentChild != null) currentChild,
              ],
            ),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.04),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: _QuestionContent(
              key: ValueKey<int>(question.id),
              question: question,
              showIntro: state.isFirstQuestion,
              selectedOptionId: state.currentSelectedOptionId,
              funFact: state.revealedFunFact,
              enabled: !state.isSubmitting,
              onOptionTap: (optionId) => _onOptionTap(question, optionId),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Dimens.spacing24,
            Dimens.spacing8,
            Dimens.spacing24,
            Dimens.spacing24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (submitError != null) ...[
                Text(
                  getString(context, submitError),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
                const SizedBox(height: Dimens.spacing12),
              ],
              Row(
                children: [
                  if (!state.isFirstQuestion) ...[
                    TextButton.icon(
                      onPressed: state.canGoPrevious ? _onPrevious : null,
                      icon: const Icon(Icons.arrow_back),
                      label: Text(getString(context, 'onboarding_previous')),
                    ),
                    const SizedBox(width: Dimens.spacing12),
                  ],
                  Expanded(
                    child: PrimaryButton(
                      text: getString(
                        context,
                        state.isLastQuestion
                            ? 'onboarding_see_profile'
                            : 'onboarding_next',
                      ),
                      isLoading: state.isSubmitting,
                      onPressed: state.canGoNext ? _onNext : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuestionContent extends StatelessWidget {
  final OnboardingQuestion question;
  final bool showIntro;
  final int? selectedOptionId;
  final String? funFact;
  final bool enabled;
  final ValueChanged<int> onOptionTap;

  const _QuestionContent({
    super.key,
    required this.question,
    required this.showIntro,
    required this.selectedOptionId,
    required this.funFact,
    required this.enabled,
    required this.onOptionTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fact = funFact;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        Dimens.spacing24,
        Dimens.spacing24,
        Dimens.spacing24,
        Dimens.spacing16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showIntro) ...[
            Text(
              getString(context, 'onboarding_subtitle'),
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: Dimens.spacing16),
          ],
          Text(
            question.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: Dimens.spacing24),
          for (final option in question.options)
            Padding(
              padding: const EdgeInsets.only(bottom: Dimens.spacing12),
              child: OnboardingOptionCard(
                label: option.label,
                selected: option.id == selectedOptionId,
                enabled: enabled,
                onTap: () => onOptionTap(option.id),
              ),
            ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SizeTransition(
                sizeFactor: animation,
                axisAlignment: -1,
                child: child,
              ),
            ),
            child: fact == null
                ? const SizedBox.shrink(key: ValueKey<String>('no_fun_fact'))
                : Padding(
                    key: const ValueKey<String>('fun_fact'),
                    padding: const EdgeInsets.only(top: Dimens.spacing8),
                    child: OnboardingFunFactCard(text: fact),
                  ),
          ),
        ],
      ),
    );
  }
}
