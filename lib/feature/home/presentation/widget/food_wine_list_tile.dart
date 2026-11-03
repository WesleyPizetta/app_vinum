import 'package:essentials/essentials.dart';
import 'package:flutter/material.dart';

import '../../domain/entity/recommended_wine.dart';
import 'match_reason_chips.dart';
import 'wine_type_label.dart';

/// Card em linha da lista de vinhos por comida: nome, tipo traduzido,
/// origem, afinidade, nota (só quando houver avaliações), até 2 motivos
/// positivos da recomendação e marcador de favorito (quando
/// [onFavoriteToggle] é informado). Também usado na busca.
class FoodWineListTile extends StatelessWidget {
  final RecommendedWine wine;
  final VoidCallback onTap;
  final VoidCallback? onFavoriteToggle;

  const FoodWineListTile({
    super.key,
    required this.wine,
    required this.onTap,
    this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = VinumPalette();
    final rating = wine.hasRating ? wine.rating : null;
    final typeLabel = wineTypeLabel(context, wine.type);
    final origin = [wine.region, wine.country]
        .whereType<String>()
        .where((part) => part.trim().isNotEmpty)
        .join(', ');
    final subtitle = [typeLabel, origin.isEmpty ? null : origin]
        .whereType<String>()
        .join(' · ');
    final mutedColor = theme.colorScheme.onSurface.withValues(alpha: 0.7);

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(Dimens.radiusLarge),
      elevation: Dimens.elevationLow,
      shadowColor: Colors.black.withValues(alpha: 0.3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Dimens.radiusLarge),
        child: Padding(
          padding: const EdgeInsets.all(Dimens.spacing12),
          child: Row(
            children: [
              // Ícone da taça
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: palette.primaryDark.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(Dimens.radiusMedium),
                ),
                child: Icon(
                  Icons.wine_bar,
                  color: palette.primaryDark,
                  size: Dimens.iconMedium,
                ),
              ),
              const SizedBox(width: Dimens.spacing12),

              // Nome, tipo/origem e nota
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      wine.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        height: 1.2,
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
                    // Nota média (0–10); sem avaliações a linha não aparece.
                    if (rating != null) ...[
                      const SizedBox(height: Dimens.spacing4),
                      Row(
                        children: [
                          Icon(
                            Icons.star_rounded,
                            size: Dimens.iconSmall,
                            color: palette.secondary,
                          ),
                          const SizedBox(width: Dimens.spacing4),
                          Text(
                            rating.toStringAsFixed(1),
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: Dimens.spacing4),
                          Text(
                            '(${wine.ratingCount})',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: mutedColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                    // Por que combina (até 2 motivos positivos).
                    if (wine.reasons.any((reason) => reason.positive)) ...[
                      const SizedBox(height: Dimens.spacing4),
                      MatchReasonChips(reasons: wine.reasons),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: Dimens.spacing8),

              // Favorito (topo) + afinidade
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (onFavoriteToggle != null) ...[
                    IconButton(
                      tooltip: getString(
                        context,
                        wine.isFavorite ? 'favorite_remove' : 'favorite_add',
                      ),
                      onPressed: onFavoriteToggle,
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                      icon: Icon(
                        wine.isFavorite
                            ? Icons.bookmark
                            : Icons.bookmark_outline,
                        size: Dimens.iconMedium,
                        color: wine.isFavorite
                            ? palette.secondary
                            : theme.colorScheme.onSurface
                                .withValues(alpha: 0.4),
                      ),
                    ),
                    const SizedBox(height: Dimens.spacing4),
                  ],
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Dimens.spacing8,
                      vertical: Dimens.spacing4,
                    ),
                    decoration: BoxDecoration(
                      color: palette.secondary.withValues(alpha: 0.18),
                      borderRadius:
                          BorderRadius.circular(Dimens.radiusMedium),
                    ),
                    child: Text(
                      getString(context, 'affinity_label').replaceAll(
                          '{percent}', '${wine.affinityPercentage}'),
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
