import 'package:essentials/essentials.dart';
import 'package:flutter/material.dart';

import '../../../home/domain/entity/wine_match.dart';
import '../../../home/presentation/widget/match_reason_labels.dart';
import '../bloc/wine_match_bloc.dart';
import '../bloc/wine_match_event.dart';
import '../bloc/wine_match_state.dart';

/// Seção "Por que este vinho combina com você?" do detalhe do vinho:
/// afinidade + todos os motivos (positivos com check, negativos com info).
///
/// Carregando/oculta: não ocupa espaço. Falha de conexão: linha discreta com
/// "tentar novamente". Requer um [WineMatchBloc] acima na árvore.
class WineMatchSection extends StatelessWidget {
  final String wineId;

  const WineMatchSection({super.key, required this.wineId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WineMatchBloc, WineMatchState>(
      builder: (context, state) {
        return switch (state) {
          WineMatchInitial() ||
          WineMatchLoading() ||
          WineMatchHidden() =>
            const SizedBox.shrink(),
          WineMatchError() => Padding(
              padding: const EdgeInsets.only(bottom: Dimens.spacing24),
              child: _RetryRow(
                onRetry: () => context
                    .read<WineMatchBloc>()
                    .add(WineMatchStarted(wineId: wineId)),
              ),
            ),
          WineMatchLoaded(:final match) => Padding(
              padding: const EdgeInsets.only(bottom: Dimens.spacing24),
              child: _MatchCard(match: match),
            ),
        };
      },
    );
  }
}

class _MatchCard extends StatelessWidget {
  final WineMatch match;

  const _MatchCard({required this.match});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = VinumPalette();
    final mutedColor = theme.colorScheme.onSurface.withValues(alpha: 0.55);

    final reasons = <({String text, bool positive})>[];
    for (final reason in match.reasons) {
      final text = matchReasonSentence(context, reason);
      if (text != null && text.isNotEmpty) {
        reasons.add((text: text, positive: reason.positive));
      }
    }

    return Container(
      padding: const EdgeInsets.all(Dimens.spacing16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(Dimens.radiusLarge),
        border: Border.all(
          color: palette.secondary.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  getString(context, 'match_section_title'),
                  style: theme.textTheme.titleMedium,
                ),
              ),
              const SizedBox(width: Dimens.spacing8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Dimens.spacing8,
                  vertical: Dimens.spacing4,
                ),
                decoration: BoxDecoration(
                  color: palette.secondary.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(Dimens.radiusMedium),
                ),
                child: Text(
                  getString(context, 'affinity_label')
                      .replaceAll('{percent}', '${match.matchPercent}'),
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Dimens.spacing12),
          if (reasons.isEmpty)
            Text(
              getString(context, 'match_no_reasons'),
              style: theme.textTheme.bodyMedium?.copyWith(color: mutedColor),
            )
          else
            for (var i = 0; i < reasons.length; i++) ...[
              if (i > 0) const SizedBox(height: Dimens.spacing8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    reasons[i].positive
                        ? Icons.check_circle
                        : Icons.info_outline,
                    size: 18,
                    color: reasons[i].positive ? palette.secondary : mutedColor,
                  ),
                  const SizedBox(width: Dimens.spacing8),
                  Expanded(
                    child: Text(
                      reasons[i].text,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ],
        ],
      ),
    );
  }
}

class _RetryRow extends StatelessWidget {
  final VoidCallback onRetry;

  const _RetryRow({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mutedColor = theme.colorScheme.onSurface.withValues(alpha: 0.6);

    return Row(
      children: [
        Icon(Icons.cloud_off_outlined, size: 18, color: mutedColor),
        const SizedBox(width: Dimens.spacing8),
        Expanded(
          child: Text(
            getString(context, 'match_error_connection'),
            style: theme.textTheme.bodySmall?.copyWith(color: mutedColor),
          ),
        ),
        TextButton(
          onPressed: onRetry,
          child: Text(getString(context, 'retry')),
        ),
      ],
    );
  }
}
