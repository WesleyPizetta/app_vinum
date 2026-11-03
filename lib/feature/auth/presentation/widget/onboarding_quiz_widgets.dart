import 'package:essentials/essentials.dart';
import 'package:flutter/material.dart';

/// Barra de progresso animada + "Pergunta X de N".
class OnboardingProgressHeader extends StatelessWidget {
  /// Número (1-based) da pergunta atual.
  final int current;
  final int total;

  const OnboardingProgressHeader({
    super.key,
    required this.current,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final double progress =
        total <= 0 ? 0.0 : (current / total).clamp(0.0, 1.0).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          getString(context, 'onboarding_question_progress')
              .replaceAll('{current}', '$current')
              .replaceAll('{total}', '$total'),
          style: theme.textTheme.labelLarge?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: Dimens.spacing8),
        ClipRRect(
          borderRadius: BorderRadius.circular(Dimens.radiusSmall),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(end: progress),
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => LinearProgressIndicator(
              value: value,
              minHeight: Dimens.spacing8,
              color: colorScheme.primary,
              backgroundColor: colorScheme.primary.withValues(alpha: 0.15),
            ),
          ),
        ),
      ],
    );
  }
}

/// Opção de resposta grande e tocável, com estado selecionado animado.
class OnboardingOptionCard extends StatelessWidget {
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const OnboardingOptionCard({
    super.key,
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  static const Duration _animationDuration = Duration(milliseconds: 200);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final borderRadius = BorderRadius.circular(Dimens.radiusLarge);

    return AnimatedScale(
      scale: selected ? 1.02 : 1.0,
      duration: _animationDuration,
      curve: Curves.easeOut,
      child: AnimatedContainer(
        duration: _animationDuration,
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: selected
              ? colorScheme.primary.withValues(alpha: 0.12)
              : colorScheme.surface,
          borderRadius: borderRadius,
          border: Border.all(
            color: selected ? colorScheme.primary : theme.dividerColor,
            width: selected ? 2 : 1,
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: borderRadius,
            onTap: enabled ? onTap : null,
            child: Semantics(
              button: true,
              selected: selected,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Dimens.spacing16,
                  vertical: Dimens.spacing20,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: Dimens.spacing12),
                    AnimatedSwitcher(
                      duration: _animationDuration,
                      transitionBuilder: (child, animation) =>
                          ScaleTransition(scale: animation, child: child),
                      child: Icon(
                        selected
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        key: ValueKey<bool>(selected),
                        color: selected
                            ? colorScheme.primary
                            : theme.dividerColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Card "Você sabia?" revelado após responder uma pergunta.
class OnboardingFunFactCard extends StatelessWidget {
  final String text;

  const OnboardingFunFactCard({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(Dimens.spacing16),
      decoration: BoxDecoration(
        color: colorScheme.secondary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(Dimens.radiusLarge),
        border: Border.all(
          color: colorScheme.secondary.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline, color: colorScheme.secondary),
          const SizedBox(width: Dimens.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  getString(context, 'onboarding_fun_fact_title'),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: Dimens.spacing4),
                Text(text, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
