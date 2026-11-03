import 'package:essentials/essentials.dart';
import 'package:flutter/material.dart';

import '../../domain/entity/daily_tip.dart';
import '../../domain/entity/learn_topic.dart';
import '../widget/learn_topic_sheet.dart';
import '../widget/learn_topic_visuals.dart';

/// Aba "Explorar": "Aprenda sobre vinhos" — conteúdo educativo leve e
/// estático (sem chamadas à API), com a "Dica do dia" e os cards dos
/// tópicos, que abrem o [showLearnTopicSheet].
///
/// Usada como conteúdo da aba (sem Scaffold próprio).
class ExplorePage extends StatelessWidget {
  const ExplorePage({super.key});

  @override
  Widget build(BuildContext context) {
    final tip = DailyTip.forDay(DateTime.now());
    // Altura dos cards acompanha o tamanho de fonte do sistema.
    final cardExtent = 84 + MediaQuery.textScalerOf(context).scale(92);

    return CustomScrollView(
      slivers: [
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(
            Dimens.spacing16,
            Dimens.spacing16,
            Dimens.spacing16,
            0,
          ),
          sliver: SliverToBoxAdapter(child: _LearnHeader()),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            Dimens.spacing16,
            Dimens.spacing16,
            Dimens.spacing16,
            0,
          ),
          sliver: SliverToBoxAdapter(child: _DailyTipCard(tip: tip)),
        ),
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(
            Dimens.spacing16,
            Dimens.spacing24,
            Dimens.spacing16,
            Dimens.spacing12,
          ),
          sliver: SliverToBoxAdapter(child: _SectionTitle()),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            Dimens.spacing16,
            0,
            Dimens.spacing16,
            Dimens.spacing32,
          ),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 240,
              mainAxisExtent: cardExtent,
              mainAxisSpacing: Dimens.spacing12,
              crossAxisSpacing: Dimens.spacing12,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final topic = LearnTopic.values[index];
                return _LearnTopicCard(
                  key: ValueKey(topic),
                  topic: topic,
                  onTap: () => showLearnTopicSheet(context, topic),
                );
              },
              childCount: LearnTopic.values.length,
            ),
          ),
        ),
      ],
    );
  }
}

class _LearnHeader extends StatelessWidget {
  const _LearnHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(Dimens.spacing20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Dimens.radiusLarge),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary,
            Color.lerp(colorScheme.primary, Colors.black, 0.25)!,
          ],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  getString(context, 'explore_learn_title'),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimary,
                  ),
                ),
                const SizedBox(height: Dimens.spacing8),
                Text(
                  getString(context, 'explore_learn_subtitle'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onPrimary.withValues(alpha: 0.9),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: Dimens.spacing16),
          Icon(
            Icons.menu_book_outlined,
            size: 44,
            color: colorScheme.onPrimary.withValues(alpha: 0.85),
          ),
        ],
      ),
    );
  }
}

class _DailyTipCard extends StatelessWidget {
  final DailyTip tip;

  const _DailyTipCard({required this.tip});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final topic = tip.topic;

    return Container(
      padding: const EdgeInsets.all(Dimens.spacing16),
      decoration: BoxDecoration(
        color: colorScheme.secondary.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(Dimens.radiusLarge),
        border: Border.all(
          color: colorScheme.secondary.withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colorScheme.secondary.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.lightbulb_outline,
              color: colorScheme.secondary,
              size: Dimens.iconMedium,
            ),
          ),
          const SizedBox(width: Dimens.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  getString(context, 'explore_daily_tip_title'),
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: Dimens.spacing4),
                Text(
                  getString(context, tip.textKey),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                    height: 1.4,
                  ),
                ),
                if (topic != null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => showLearnTopicSheet(context, topic),
                      child: Text(getString(context, 'explore_daily_tip_more')),
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Text(
      getString(context, 'explore_topics_title'),
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.onSurface,
      ),
    );
  }
}

class _LearnTopicCard extends StatelessWidget {
  final LearnTopic topic;
  final VoidCallback onTap;

  const _LearnTopicCard({
    super.key,
    required this.topic,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accent = learnTopicAccent(colorScheme, topic);

    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(Dimens.radiusLarge),
      elevation: Dimens.elevationLow,
      shadowColor: Colors.black.withValues(alpha: 0.3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Dimens.radiusLarge),
        child: Padding(
          padding: const EdgeInsets.all(Dimens.spacing16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(Dimens.radiusMedium),
                ),
                child: Icon(
                  learnTopicIcon(topic),
                  color: accent,
                  size: Dimens.iconMedium,
                ),
              ),
              const SizedBox(height: Dimens.spacing12),
              Text(
                getString(context, topic.titleKey),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: Dimens.spacing4),
              Expanded(
                child: Text(
                  getString(context, topic.summaryKey),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
