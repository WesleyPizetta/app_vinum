import 'package:essentials/essentials.dart';
import 'package:flutter/material.dart';

import '../../../home/presentation/widget/wine_type_label.dart';
import '../../domain/entity/onboarding_result.dart';

/// Nível de uma característica (corpo/acidez) na escala 1–3 do backend.
enum TasteLevel {
  low,
  medium,
  high;

  /// Divide a escala 1–3 em três faixas iguais.
  static TasteLevel fromScore(double score) {
    if (score < 5 / 3) return TasteLevel.low;
    if (score < 7 / 3) return TasteLevel.medium;
    return TasteLevel.high;
  }
}

/// Tela "Seu perfil de gosto", exibida após o envio bem-sucedido do quiz.
class OnboardingResultView extends StatelessWidget {
  final OnboardingResult result;
  final String actionLabel;
  final VoidCallback onAction;

  const OnboardingResultView({
    super.key,
    required this.result,
    required this.actionLabel,
    required this.onAction,
  });

  /// Score válido na escala 1–3 (o model usa 0 quando o campo vem ausente).
  static bool _hasScore(double score) => score >= 1;

  static const List<String> _bodyKeys = [
    'onboarding_body_light',
    'onboarding_body_medium',
    'onboarding_body_full',
  ];

  static const List<String> _acidityKeys = [
    'onboarding_acidity_low',
    'onboarding_acidity_medium',
    'onboarding_acidity_high',
  ];

  String _description(BuildContext context, String? typeLabel) {
    final sentences = <String>[];
    if (_hasScore(result.bodyScore)) {
      final level = TasteLevel.fromScore(result.bodyScore);
      sentences.add(getString(
        context,
        switch (level) {
          TasteLevel.low => 'onboarding_result_description_body_light',
          TasteLevel.medium => 'onboarding_result_description_body_medium',
          TasteLevel.high => 'onboarding_result_description_body_full',
        },
      ));
    }
    if (_hasScore(result.acidityScore)) {
      final level = TasteLevel.fromScore(result.acidityScore);
      sentences.add(getString(
        context,
        switch (level) {
          TasteLevel.low => 'onboarding_result_description_acidity_low',
          TasteLevel.medium => 'onboarding_result_description_acidity_medium',
          TasteLevel.high => 'onboarding_result_description_acidity_high',
        },
      ));
    }
    if (typeLabel != null) {
      sentences.add(
        getString(context, 'onboarding_result_description_type')
            .replaceAll('{type}', typeLabel),
      );
    } else {
      sentences.add(getString(context, 'onboarding_result_description_generic'));
    }
    return sentences.join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final typeLabel = wineTypeLabel(context, result.preferredType);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Dimens.spacing24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: Dimens.spacing8),
                Center(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.6, end: 1),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.elasticOut,
                    builder: (context, scale, child) =>
                        Transform.scale(scale: scale, child: child),
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor:
                          colorScheme.primary.withValues(alpha: 0.15),
                      child: Icon(
                        Icons.wine_bar,
                        size: 40,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: Dimens.spacing16),
                Text(
                  getString(context, 'onboarding_result_title'),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: Dimens.spacing8),
                Text(
                  getString(context, 'onboarding_result_subtitle'),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: Dimens.spacing24),
                if (typeLabel != null) ...[
                  _PreferredTypeCard(label: typeLabel),
                  const SizedBox(height: Dimens.spacing16),
                ],
                if (_hasScore(result.bodyScore)) ...[
                  _TasteMeter(
                    title: getString(context, 'onboarding_result_body'),
                    score: result.bodyScore,
                    levelKeys: _bodyKeys,
                  ),
                  const SizedBox(height: Dimens.spacing16),
                ],
                if (_hasScore(result.acidityScore)) ...[
                  _TasteMeter(
                    title: getString(context, 'onboarding_result_acidity'),
                    score: result.acidityScore,
                    levelKeys: _acidityKeys,
                  ),
                  const SizedBox(height: Dimens.spacing16),
                ],
                Text(
                  _description(context, typeLabel),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Dimens.spacing24,
            0,
            Dimens.spacing24,
            Dimens.spacing24,
          ),
          child: PrimaryButton(text: actionLabel, onPressed: onAction),
        ),
      ],
    );
  }
}

class _PreferredTypeCard extends StatelessWidget {
  final String label;

  const _PreferredTypeCard({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Dimens.spacing16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: colorScheme.primary.withValues(alpha: 0.15),
              child: Icon(Icons.favorite, color: colorScheme.primary),
            ),
            const SizedBox(width: Dimens.spacing16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    getString(context, 'onboarding_result_preferred_type'),
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: Dimens.spacing4),
                  Text(
                    label,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Medidor 1–3 com a faixa atual em destaque (ex.: Leve / Médio / Encorpado).
class _TasteMeter extends StatelessWidget {
  final String title;
  final double score;

  /// Chaves i18n dos níveis baixo, médio e alto, nessa ordem.
  final List<String> levelKeys;

  const _TasteMeter({
    required this.title,
    required this.score,
    required this.levelKeys,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final level = TasteLevel.fromScore(score);
    final double normalized = ((score - 1) / 2).clamp(0.0, 1.0).toDouble();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Dimens.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(title, style: theme.textTheme.titleMedium),
                ),
                Text(
                  getString(context, levelKeys[level.index]),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Dimens.spacing12),
            ClipRRect(
              borderRadius: BorderRadius.circular(Dimens.radiusSmall),
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: normalized),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => LinearProgressIndicator(
                  value: value,
                  minHeight: Dimens.spacing12,
                  color: colorScheme.primary,
                  backgroundColor: colorScheme.primary.withValues(alpha: 0.15),
                ),
              ),
            ),
            const SizedBox(height: Dimens.spacing8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var i = 0; i < levelKeys.length; i++)
                  Text(
                    getString(context, levelKeys[i]),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: i == level.index
                          ? FontWeight.w700
                          : FontWeight.w400,
                      color: i == level.index ? colorScheme.primary : null,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
