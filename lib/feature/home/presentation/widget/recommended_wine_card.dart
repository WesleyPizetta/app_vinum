import 'package:essentials/essentials.dart';
import 'package:flutter/material.dart';

import '../../domain/entity/recommended_wine.dart';

/// Card individual de recomendação de vinho com informações de nota, preço e afinidade.
class RecommendedWineCard extends StatelessWidget {
  final RecommendedWine wine;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onTap;

  const RecommendedWineCard({
    super.key,
    required this.wine,
    required this.onFavoriteToggle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = VinumPalette();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Dimens.radiusLarge),
      child: Container(
        width: 145,
        height: 160,
        padding: const EdgeInsets.all(Dimens.spacing12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(Dimens.radiusLarge),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Topo: Nome do vinho + Ícone de Favorito / Marcador
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    wine.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: onFavoriteToggle,
                  child: Icon(
                    wine.isFavorite ? Icons.bookmark : Icons.bookmark_outline,
                    size: Dimens.iconMedium,
                    color: wine.isFavorite
                        ? palette.secondary
                        : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),

            // Nota (Estrela)
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
              ],
            ),

            // Preço + Ícone de Taça de Vinho
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'R\$ ${wine.price.toStringAsFixed(0)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Icon(
                  Icons.wine_bar,
                  size: Dimens.iconSmall,
                  color: palette.primaryDark,
                ),
              ],
            ),

            // Porcentagem de Afinidade
            Text(
              getString(context, 'affinity_label')
                  .replaceAll('{percent}', '${wine.affinityPercentage}'),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
