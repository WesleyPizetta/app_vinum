import 'package:essentials/essentials.dart';
import 'package:flutter/material.dart';

import '../../domain/entity/learn_topic.dart';
import 'learn_topic_visuals.dart';

/// Abre o conteúdo educativo de [topic] em um bottom sheet rolável.
///
/// Pode ser chamado de qualquer tela (ex.: atalho "o que é corpo?" no
/// detalhe do vinho). Completa quando o sheet é fechado.
Future<void> showLearnTopicSheet(BuildContext context, LearnTopic topic) {
  final colorScheme = Theme.of(context).colorScheme;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(Dimens.radiusXLarge),
      ),
    ),
    builder: (_) => _LearnTopicSheet(topic: topic),
  );
}

class _LearnTopicSheet extends StatelessWidget {
  final LearnTopic topic;

  const _LearnTopicSheet({required this.topic});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accent = learnTopicAccent(colorScheme, topic);
    final mutedColor = colorScheme.onSurface.withValues(alpha: 0.7);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) => ListView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(
          Dimens.spacing24,
          0,
          Dimens.spacing24,
          Dimens.spacing32,
        ),
        children: [
          // ── Cabeçalho ──
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(Dimens.radiusLarge),
                ),
                child: Icon(
                  learnTopicIcon(topic),
                  color: accent,
                  size: Dimens.iconLarge,
                ),
              ),
              const SizedBox(width: Dimens.spacing16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      getString(context, topic.titleKey),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: Dimens.spacing4),
                    Text(
                      getString(context, topic.summaryKey),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: mutedColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Dimens.spacing24),

          // ── Introdução ──
          Text(
            getString(context, topic.introKey),
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface,
              height: 1.45,
            ),
          ),
          const SizedBox(height: Dimens.spacing20),

          // ── Tópicos ──
          for (final pointKey in topic.pointKeys)
            _LearnPoint(
              text: getString(context, pointKey),
              accent: accent,
            ),
          const SizedBox(height: Dimens.spacing12),

          // ── Na prática ──
          _PracticalTip(text: getString(context, topic.tipKey)),
          const SizedBox(height: Dimens.spacing24),

          Align(
            alignment: Alignment.center,
            child: FilledButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: Text(getString(context, 'learn_sheet_close')),
            ),
          ),
        ],
      ),
    );
  }
}

class _LearnPoint extends StatelessWidget {
  final String text;
  final Color accent;

  const _LearnPoint({required this.text, required this.accent});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: Dimens.spacing12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: Dimens.spacing2),
            child: Icon(
              Icons.check_circle_outline,
              size: Dimens.iconSmall + 2,
              color: accent,
            ),
          ),
          const SizedBox(width: Dimens.spacing12),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PracticalTip extends StatelessWidget {
  final String text;

  const _PracticalTip({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(Dimens.spacing16),
      decoration: BoxDecoration(
        color: colorScheme.secondary.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(Dimens.radiusLarge),
        border: Border.all(
          color: colorScheme.secondary.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lightbulb_outline,
            color: colorScheme.secondary,
            size: Dimens.iconMedium,
          ),
          const SizedBox(width: Dimens.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  getString(context, 'learn_sheet_tip_title'),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: Dimens.spacing4),
                Text(
                  text,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
