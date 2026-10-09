import 'package:essentials/essentials.dart';
import 'package:flutter/material.dart';

import '../../../review/domain/entity/review_tag.dart';
import '../../../review/presentation/widget/review_tag_badge.dart';
import '../../../wine/presentation/widget/wine_labels.dart';
import '../../domain/entity/cellar_review.dart';
import 'cellar_format.dart';

/// Card de "Minha adega": vinho avaliado, minha nota, trecho do comentário,
/// tags e data da avaliação.
class CellarReviewTile extends StatelessWidget {
  final CellarReview review;
  final VoidCallback onTap;

  const CellarReviewTile({
    super.key,
    required this.review,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final mutedColor = colorScheme.onSurface.withValues(alpha: 0.7);
    final wine = review.wine;

    final name = wine?.name ??
        getString(context, 'cellar_unknown_wine')
            .replaceAll('{id}', review.wineId);
    final typeLabel =
        wine == null ? '' : translateWineLabel(context, 'wine_type', wine.type);
    final subtitle = [typeLabel, wine?.winery ?? '']
        .where((part) => part.trim().isNotEmpty)
        .join(' · ');
    final comment = review.comment;
    final createdAt = review.createdAt;
    final tags = review.tags.toSet().toList(growable: false);

    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(Dimens.radiusLarge),
      elevation: Dimens.elevationLow,
      shadowColor: Colors.black.withValues(alpha: 0.3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Dimens.radiusLarge),
        child: Padding(
          padding: const EdgeInsets.all(Dimens.spacing12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(Dimens.radiusMedium),
                    ),
                    child: Icon(
                      Icons.wine_bar,
                      color: colorScheme.primary,
                      size: Dimens.iconMedium,
                    ),
                  ),
                  const SizedBox(width: Dimens.spacing12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        if (subtitle.isNotEmpty) ...[
                          const SizedBox(height: Dimens.spacing4),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: mutedColor,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: Dimens.spacing8),
                  _RatingPill(rating: review.rating),
                ],
              ),
              if (comment != null) ...[
                const SizedBox(height: Dimens.spacing12),
                Text(
                  '“$comment”',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: colorScheme.onSurface.withValues(alpha: 0.85),
                    height: 1.35,
                  ),
                ),
              ],
              if (tags.isNotEmpty) ...[
                const SizedBox(height: Dimens.spacing12),
                Wrap(
                  spacing: Dimens.spacing8,
                  runSpacing: Dimens.spacing8,
                  children: [
                    for (final code in tags) _TagChip(code: code),
                  ],
                ),
              ],
              if (createdAt != null) ...[
                const SizedBox(height: Dimens.spacing12),
                Row(
                  children: [
                    Icon(
                      Icons.event_outlined,
                      size: Dimens.iconSmall,
                      color: mutedColor,
                    ),
                    const SizedBox(width: Dimens.spacing4),
                    Expanded(
                      child: Text(
                        getString(context, 'cellar_reviewed_on').replaceAll(
                          '{date}',
                          formatCellarDate(context, createdAt),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: mutedColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Minha nota: estrela + "8,5/10".
class _RatingPill extends StatelessWidget {
  final double rating;

  const _RatingPill({required this.rating});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimens.spacing8,
        vertical: Dimens.spacing4,
      ),
      decoration: BoxDecoration(
        color: colorScheme.secondary.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(Dimens.radiusXLarge),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star_rounded,
            size: Dimens.iconSmall,
            color: colorScheme.secondary,
          ),
          const SizedBox(width: Dimens.spacing4),
          Text(
            formatCellarRatingOutOfTen(context, rating),
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tag conhecida usa o badge das avaliações; desconhecida aparece como veio.
class _TagChip extends StatelessWidget {
  final String code;

  const _TagChip({required this.code});

  @override
  Widget build(BuildContext context) {
    final tag = ReviewTag.fromCode(code);
    if (tag != null) return ReviewTagBadge(tag: tag, compact: true);

    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimens.spacing8,
        vertical: Dimens.spacing4,
      ),
      decoration: ShapeDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
        shape: StadiumBorder(
          side: BorderSide(color: theme.dividerColor),
        ),
      ),
      child: Text(
        code,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
