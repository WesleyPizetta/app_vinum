import 'package:essentials/essentials.dart';
import 'package:flutter/material.dart';

import '../../domain/entity/wine_match_reason.dart';
import 'match_reason_labels.dart';

/// Linhas compactas com os motivos de uma recomendação (ex.: "Tinto, seu
/// tipo favorito"), cada uma com ícone e no máximo uma linha de texto.
///
/// Por padrão mostra até [maxItems] motivos positivos (uso nos cards). Com
/// [positiveOnly] `false` mostra também os negativos (ícone de informação).
/// Motivos de código desconhecido são ignorados; sem nenhum motivo exibível
/// o widget não ocupa espaço.
class MatchReasonChips extends StatelessWidget {
  final List<WineMatchReason> reasons;
  final int? maxItems;
  final bool positiveOnly;

  /// Tamanho da fonte; `null` usa o `labelSmall` do tema.
  final double? fontSize;

  /// Linhas por motivo (1 nos cards, com reticências).
  final int maxLines;

  const MatchReasonChips({
    super.key,
    required this.reasons,
    this.maxItems = 2,
    this.positiveOnly = true,
    this.fontSize,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final entries = <({String text, bool positive})>[];
    for (final reason in reasons) {
      if (maxItems != null && entries.length >= maxItems!) break;
      if (positiveOnly && !reason.positive) continue;
      final text = matchReasonSentence(context, reason);
      if (text == null || text.isEmpty) continue;
      entries.add((text: text, positive: reason.positive));
    }
    if (entries.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final palette = VinumPalette();
    final textStyle = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
      fontSize: fontSize,
    );
    final iconSize = (fontSize ?? textStyle?.fontSize ?? 11) + 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < entries.length; i++) ...[
          if (i > 0) const SizedBox(height: Dimens.spacing2),
          Row(
            crossAxisAlignment: maxLines > 1
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              Icon(
                entries[i].positive
                    ? Icons.check_circle_outline
                    : Icons.info_outline,
                size: iconSize,
                color: entries[i].positive
                    ? palette.secondary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              const SizedBox(width: Dimens.spacing4),
              Expanded(
                child: Text(
                  entries[i].text,
                  maxLines: maxLines,
                  overflow: TextOverflow.ellipsis,
                  style: textStyle,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
