import 'package:essentials/essentials.dart';
import 'package:flutter/material.dart';

import 'cellar_format.dart';

/// Resumo da adega: quantidade de avaliações carregadas ("20+" quando há
/// mais páginas) e a média das minhas notas.
class CellarSummaryHeader extends StatelessWidget {
  final int count;
  final bool hasMore;
  final double? averageRating;

  const CellarSummaryHeader({
    super.key,
    required this.count,
    required this.hasMore,
    this.averageRating,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final average = averageRating;

    return Container(
      padding: const EdgeInsets.all(Dimens.spacing16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            getString(context, 'cellar_title'),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onPrimary,
            ),
          ),
          const SizedBox(height: Dimens.spacing4),
          Text(
            getString(context, 'cellar_subtitle'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onPrimary.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: Dimens.spacing16),
          Row(
            children: [
              Expanded(
                child: _StatBox(
                  icon: Icons.wine_bar_outlined,
                  value: hasMore ? '$count+' : '$count',
                  label: getString(
                    context,
                    count == 1 && !hasMore
                        ? 'cellar_reviews_label_one'
                        : 'cellar_reviews_label',
                  ),
                ),
              ),
              const SizedBox(width: Dimens.spacing12),
              Expanded(
                child: _StatBox(
                  icon: Icons.star_rounded,
                  value: average == null
                      ? '–'
                      : formatCellarRating(context, average),
                  label: getString(context, 'cellar_average_label'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatBox({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onPrimary = theme.colorScheme.onPrimary;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimens.spacing12,
        vertical: Dimens.spacing8,
      ),
      decoration: BoxDecoration(
        color: onPrimary.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(Dimens.radiusMedium),
      ),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.secondary, size: Dimens.iconMedium),
          const SizedBox(width: Dimens.spacing8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: onPrimary,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: onPrimary.withValues(alpha: 0.85),
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
