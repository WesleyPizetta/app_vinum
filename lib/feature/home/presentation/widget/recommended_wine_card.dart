import 'package:essentials/essentials.dart';
import 'package:flutter/material.dart';

import '../../domain/entity/recommended_wine.dart';
import 'match_reason_chips.dart';
import 'wine_type_label.dart';

/// Card individual de recomendação de vinho com tipo, origem, nota (quando
/// houver avaliações), até 2 motivos positivos ("por que combina") e
/// afinidade com o perfil do usuário.
class RecommendedWineCard extends StatelessWidget {
  final RecommendedWine wine;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onTap;

  /// Tamanho fixo do card. A lista horizontal e a seção da home usam a
  /// mesma altura; o espaço comporta nome (2 linhas), nota, tipo, origem,
  /// 2 motivos e afinidade.
  static const double height = 190;
  static const double width = 145;

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
    final rating = wine.hasRating ? wine.rating : null;
    final typeLabel = wineTypeLabel(context, wine.type);
    final origin = [wine.region, wine.country]
        .whereType<String>()
        .where((part) => part.trim().isNotEmpty)
        .join(', ');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Dimens.radiusLarge),
      child: Container(
        width: width,
        height: height,
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

            // Nota média das avaliações (0–10, mesma escala dos reviews).
            // Sem avaliações: a linha não é exibida.
            if (rating != null)
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
                  Flexible(
                    child: Text(
                      '(${wine.ratingCount})',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ],
              ),

            // Tipo (traduzido) + Ícone de Taça de Vinho
            if (typeLabel != null)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      typeLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.wine_bar,
                    size: Dimens.iconSmall,
                    color: palette.primaryDark,
                  ),
                ],
              ),

            // Origem (região, país)
            if (origin.isNotEmpty)
              Text(
                origin,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),

            // Por que combina (até 2 motivos positivos, 1 linha cada)
            if (wine.reasons.any((reason) => reason.positive))
              MatchReasonChips(reasons: wine.reasons, fontSize: 10),

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
