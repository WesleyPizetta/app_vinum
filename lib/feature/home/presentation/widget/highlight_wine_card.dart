import 'package:essentials/essentials.dart';
import 'package:flutter/material.dart';

import '../../domain/entity/highlight_wine.dart';
import 'wine_type_label.dart';

/// Card individual para os "Destaques da Semana" exibindo o banner (cor pelo
/// tipo do vinho), nome, nota média com estrela (quando houver avaliações) e
/// o tipo traduzido.
class HighlightWineCard extends StatelessWidget {
  final HighlightWine wine;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onTap;

  /// Altura fixa do card (a lista horizontal usa o mesmo valor).
  static const double height = 195;
  static const double width = 140;

  const HighlightWineCard({
    super.key,
    required this.wine,
    required this.onFavoriteToggle,
    required this.onTap,
  });

  /// Cor do banner de acordo com o tipo vindo da API.
  static Color bannerColorFor(String? type) {
    final normalized = (type ?? '').toLowerCase().replaceAll('é', 'e');
    if (normalized.contains('sparkling')) return const Color(0xFF2C5570);
    if (normalized.contains('rose')) return const Color(0xFFB5566E);
    if (normalized.contains('dessert') || normalized.contains('port')) {
      return const Color(0xFF6A3F7A);
    }
    if (normalized.contains('white')) return const Color(0xFFCFA035);
    if (normalized.contains('red')) return const Color(0xFF6B1F32);
    return const Color(0xFF4A121A);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = VinumPalette();
    final rating = wine.hasRating ? wine.rating : null;
    final typeLabel = wineTypeLabel(context, wine.type);
    final mutedColor = theme.colorScheme.onSurface.withValues(alpha: 0.6);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Dimens.radiusLarge),
      child: Container(
        width: width,
        height: height,
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
                color: bannerColorFor(wine.type),
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

            // Informações inferiores: nome, nota e tipo
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
                      children: [
                        // Nota média (0–10); sem avaliações não aparece.
                        if (rating != null) ...[
                          Icon(
                            Icons.star_rounded,
                            size: Dimens.iconSmall,
                            color: palette.secondary,
                          ),
                          const SizedBox(width: Dimens.spacing2),
                          Text(
                            rating.toStringAsFixed(1),
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: Dimens.spacing8),
                        ],
                        if (typeLabel != null)
                          Expanded(
                            child: Text(
                              typeLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: rating != null
                                  ? TextAlign.end
                                  : TextAlign.start,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: mutedColor,
                                fontSize: 11,
                              ),
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
