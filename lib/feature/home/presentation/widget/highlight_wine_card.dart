import 'package:essentials/essentials.dart';
import 'package:flutter/material.dart';

import '../../domain/entity/highlight_wine.dart';

/// Card individual para os "Destaques da Semana" exibindo o banner do rótulo,
/// nome do vinho, avaliação com estrela e contagem de visualizações/avaliações.
class HighlightWineCard extends StatelessWidget {
  final HighlightWine wine;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onTap;

  const HighlightWineCard({
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
        width: 140,
        height: 195,
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Banner superior colorido com a garrafa e o botão de favorito
            Container(
              height: 105,
              decoration: BoxDecoration(
                color: wine.bannerColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(Dimens.radiusLarge),
                  topRight: Radius.circular(Dimens.radiusLarge),
                ),
              ),
              child: Stack(
                children: [
                  // Ícone/Rótulo de garrafa centralizado
                  Center(
                    child: Icon(
                      Icons.wine_bar,
                      size: 52,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  // Botão de Favorito / Marcador no canto superior direito
                  Positioned(
                    top: Dimens.spacing8,
                    right: Dimens.spacing8,
                    child: IconButton(
                      onPressed: onFavoriteToggle,
                      tooltip: getString(
                        context,
                        wine.isFavorite
                            ? 'remove_from_favorites'
                            : 'add_to_favorites',
                      ),
                      icon: Icon(
                        wine.isFavorite
                            ? Icons.bookmark
                            : Icons.bookmark_outline,
                        size: Dimens.iconMedium,
                        color: wine.isFavorite
                            ? palette.secondary
                            : Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Informações inferiores: Nome, Nota e Contagem de Visualizações
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Dimens.spacing12,
                  vertical: Dimens.spacing8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      wine.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        height: 1.15,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.star_rounded,
                              size: Dimens.iconSmall,
                              color: palette.secondary,
                            ),
                            const SizedBox(width: Dimens.spacing2),
                            Text(
                              wine.rating.toStringAsFixed(1),
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          wine.viewsCountLabel,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
