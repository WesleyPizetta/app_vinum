import 'package:essentials/essentials.dart';
import 'package:flutter/material.dart';

import '../../../../core/navigation/application_route.dart';
import '../../domain/entity/recommended_wine.dart';
import '../bloc/home_bloc.dart';
import '../bloc/home_event.dart';
import '../bloc/home_state.dart';
import 'recommended_wine_card.dart';
import 'recommended_wines_horizontal_list.dart';

/// Conteúdo da seção "Sugestões para você" de acordo com o
/// [RecommendationsStatus]. Falhas aqui não afetam o resto da home.
class RecommendedWinesSection extends StatelessWidget {
  final RecommendationsStatus status;
  final List<RecommendedWine> recommendations;

  /// Chave i18n do erro (status `error`).
  final String? errorMessage;

  /// Mesma altura dos cards, para a home não "pular" ao trocar de estado.
  static const double _sectionHeight = RecommendedWineCard.height;

  const RecommendedWinesSection({
    super.key,
    required this.status,
    required this.recommendations,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      RecommendationsStatus.loading => const SizedBox(
          height: _sectionHeight,
          child: LoadingWidget(),
        ),
      RecommendationsStatus.loaded => Padding(
          padding: const EdgeInsets.only(left: Dimens.spacing24),
          child: RecommendedWinesHorizontalList(
            recommendations: recommendations,
          ),
        ),
      RecommendationsStatus.empty => _SectionMessage(
          icon: Icons.wine_bar_outlined,
          message: getString(context, 'home_recommendations_empty'),
        ),
      RecommendationsStatus.error => _SectionMessage(
          icon: Icons.error_outline,
          message: getString(
            context,
            errorMessage ?? 'home_recommendations_error_load',
          ),
          actionLabel: getString(context, 'retry'),
          actionIcon: Icons.refresh,
          // "Tentar novamente": HomeStarted recarrega só a seção quando a
          // home já está carregada.
          onAction: () => context.read<HomeBloc>().add(HomeStarted()),
        ),
      RecommendationsStatus.onboardingRequired => _SectionMessage(
          icon: Icons.quiz_outlined,
          message: getString(
            context,
            'home_recommendations_onboarding_required',
          ),
          actionLabel: getString(context, 'home_recommendations_take_quiz'),
          actionIcon: Icons.arrow_forward,
          onAction: () =>
              Navigator.pushNamed(context, ApplicationRoute.onboarding),
        ),
    };
  }
}

class _SectionMessage extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;

  const _SectionMessage({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Dimens.spacing24),
      child: Container(
        padding: const EdgeInsets.all(Dimens.spacing16),
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
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  icon,
                  size: Dimens.iconMedium,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: Dimens.spacing12),
                Expanded(
                  child: Text(
                    message,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: Dimens.spacing12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onAction,
                  icon: Icon(actionIcon ?? Icons.arrow_forward, size: 18),
                  label: Text(actionLabel!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
