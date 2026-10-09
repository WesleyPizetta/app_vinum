import 'package:essentials/essentials.dart';
import 'package:flutter/material.dart';

import '../../../home/presentation/widget/wine_type_label.dart';
import '../../domain/entity/favorite_wine.dart';

/// Card em linha de "Meus favoritos": nome, tipo traduzido, origem, nota
/// (só quando houver avaliações) e o marcador para desfavoritar.
class FavoriteWineListTile extends StatelessWidget {
  final FavoriteWine favorite;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const FavoriteWineListTile({
    super.key,
    required this.favorite,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = VinumPalette();
    final wine = favorite.wine;
    final typeLabel = wineTypeLabel(context, wine.type);
    final origin = [wine.region, wine.country]
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
                    if (wine.winery.isNotEmpty) ...[
                      const SizedBox(height: Dimens.spacing2),
                      Text(
                        wine.winery,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: mutedColor,
                        ),
                      ),
                    ],
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
                    if (wine.hasRating) ...[
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
                            wine.rating.toStringAsFixed(1),
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
                  ],
                ),
              ),
              IconButton(
                tooltip: getString(context, 'favorite_remove'),
                onPressed: onRemove,
                icon: Icon(Icons.bookmark, color: palette.secondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
