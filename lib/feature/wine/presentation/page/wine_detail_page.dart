import 'package:essentials/essentials.dart';
import 'package:flutter/material.dart';

import '../../../../feature/auth/domain/entity/user.dart';
import '../../../../feature/auth/domain/repository/auth_repository.dart';
import '../../../../feature/review/domain/entity/review.dart';
import '../../../../feature/review/presentation/bloc/review_form_bloc.dart';
import '../../../../feature/review/presentation/bloc/review_form_state.dart';
import '../../../../feature/review/presentation/bloc/review_list_bloc.dart';
import '../../../../feature/review/presentation/bloc/review_list_event.dart';
import '../../../../feature/review/presentation/bloc/review_list_state.dart';
import '../../../../feature/review/presentation/widget/review_card.dart';
import '../../../../feature/review/presentation/widget/review_form_sheet.dart';
import '../../../explore/domain/entity/learn_topic.dart';
import '../../../explore/presentation/widget/learn_topic_sheet.dart';
import '../../../favorites/presentation/widget/favorite_icon_button.dart';
import '../../../home/presentation/widget/wine_type_label.dart';
import '../../domain/entity/wine.dart';
import '../bloc/wine_detail_bloc.dart';
import '../bloc/wine_detail_event.dart';
import '../bloc/wine_detail_state.dart';
import '../bloc/wine_match_bloc.dart';
import '../bloc/wine_match_event.dart';
import '../widget/wine_labels.dart';
import '../widget/wine_match_section.dart';

class WineDetailPage extends StatelessWidget {
  final AuthRepository? authRepository;

  const WineDetailPage({super.key, this.authRepository});

  @override
  Widget build(BuildContext context) {
    final wineId = ModalRoute.of(context)!.settings.arguments as String;
    final authRepo =
        authRepository ?? ApplicationContainer.resolve<AuthRepository>();
    final currentUser = authRepo.getCurrentUser();
    final token = authRepo.getAccessToken();

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => ApplicationContainer.resolve<WineDetailBloc>()
            ..add(WineDetailStarted(wineId: wineId)),
        ),
        BlocProvider(
          create: (_) => ApplicationContainer.resolve<ReviewListBloc>()
            ..add(ReviewListStarted(wineId: wineId)),
        ),
        BlocProvider(
          create: (_) => ApplicationContainer.resolve<ReviewFormBloc>(),
        ),
        // "Por que este vinho combina com você?" (falhas só ocultam a seção).
        BlocProvider(
          create: (_) => ApplicationContainer.resolve<WineMatchBloc>()
            ..add(WineMatchStarted(wineId: wineId)),
        ),
      ],
      child: _WineDetailPageContent(
        wineId: wineId,
        currentUser: currentUser,
        token: token,
      ),
    );
  }
}

class _WineDetailPageContent extends StatelessWidget {
  final String wineId;
  final User? currentUser;
  final String? token;

  const _WineDetailPageContent({
    required this.wineId,
    required this.currentUser,
    required this.token,
  });

  @override
  Widget build(BuildContext context) {
    final currentToken = token;
    final user = currentUser;

    return BlocListener<ReviewFormBloc, ReviewFormState>(
      listener: (context, state) {
        if (state is ReviewFormLoading &&
            state.operation == ReviewFormOperation.delete) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(
                duration: Duration(days: 1),
                content: Text('Excluindo avaliação...'),
              ),
            );
          return;
        }

        if (state is ReviewFormSuccess) {
          if (state.operation == ReviewFormOperation.delete) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            showVinumSuccessModal(
              context,
              message: 'Avaliação excluída com sucesso!',
            );
          }

          context.read<ReviewListBloc>().add(ReviewListStarted(wineId: wineId));
          return;
        }

        if (state is ReviewFormError &&
            state.operation == ReviewFormOperation.delete) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          showVinumErrorModal(context, message: state.message);
        }
      },
      child: Scaffold(
        body: BlocBuilder<WineDetailBloc, WineDetailState>(
          builder: (context, state) {
            return switch (state) {
              WineDetailInitial() => const SizedBox.shrink(),
              WineDetailLoading() => const LoadingWidget(),
              WineDetailLoaded(:final wine) => _WineDetailContent(
                  wine: wine,
                  wineId: wineId,
                  currentUserId: user?.id,
                  token: currentToken,
                ),
              WineDetailError(:final message) => SafeArea(
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: BackButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                        ),
                      ),
                      Expanded(
                        child: VinumErrorWidget(
                          message: getString(context, message),
                          onRetry: () => context
                              .read<WineDetailBloc>()
                              .add(WineDetailStarted(wineId: wineId)),
                        ),
                      ),
                    ],
                  ),
                ),
            };
          },
        ),
        floatingActionButton: currentToken != null && user != null
            ? _ReviewFloatingActionButton(
                wineId: wineId,
                token: currentToken,
                currentUserId: user.id,
              )
            : null,
      ),
    );
  }
}

class _ReviewFloatingActionButton extends StatelessWidget {
  final String wineId;
  final String token;
  final String currentUserId;

  const _ReviewFloatingActionButton({
    required this.wineId,
    required this.token,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReviewListBloc, ReviewListState>(
      builder: (context, state) {
        final existingReview = switch (state) {
          ReviewListLoaded(:final reviews) => _findUserReview(reviews),
          _ => null,
        };

        final isEdit = existingReview != null;

        return FloatingActionButton(
          tooltip: isEdit ? 'Editar minha avaliação' : 'Adicionar avaliação',
          onPressed: () => showReviewFormSheet(
            context,
            wineId: wineId,
            token: token,
            existingReview: existingReview,
          ),
          child:
              Icon(isEdit ? Icons.edit_outlined : Icons.rate_review_outlined),
        );
      },
    );
  }

  Review? _findUserReview(List<Review> reviews) {
    for (final review in reviews) {
      if (review.usuarioId == currentUserId) {
        return review;
      }
    }
    return null;
  }
}

class _WineDetailContent extends StatelessWidget {
  final Wine wine;
  final String wineId;
  final String? currentUserId;
  final String? token;

  const _WineDetailContent({
    required this.wine,
    required this.wineId,
    this.currentUserId,
    this.token,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final origin = [wine.region, wine.country]
        .where((part) => part.trim().isNotEmpty)
        .join(', ');
    final typeLabel = wineTypeLabel(context, wine.type);
    // Tipo, corpo e acidez abrem o conteúdo educativo do Explorar.
    final chips = <_InfoChip>[
      if (typeLabel != null)
        _InfoChip(
          icon: Icons.wine_bar,
          label: typeLabel,
          onTap: () => showLearnTopicSheet(context, LearnTopic.types),
        ),
      if (wine.grape.isNotEmpty) _InfoChip(icon: Icons.grass, label: wine.grape),
      if (wine.body.isNotEmpty)
        _InfoChip(
          icon: Icons.water_drop_outlined,
          label: translateWineLabel(context, 'wine_body', wine.body),
          onTap: () => showLearnTopicSheet(context, LearnTopic.body),
        ),
      if (wine.acidity.isNotEmpty)
        _InfoChip(
          icon: Icons.bolt_outlined,
          label:
              '${getString(context, 'wine_acidity')}: ${translateWineLabel(context, 'wine_level', wine.acidity)}',
          onTap: () => showLearnTopicSheet(context, LearnTopic.acidity),
        ),
      if (wine.abv != null)
        _InfoChip(
          icon: Icons.percent,
          label: '${wine.abv!.toStringAsFixed(1)}%',
        ),
      if (wine.vintage > 0)
        _InfoChip(icon: Icons.calendar_today, label: '${wine.vintage}'),
      if (wine.hasRating)
        _InfoChip(
          icon: Icons.star_rounded,
          label: '${wine.rating.toStringAsFixed(1)} (${wine.ratingCount})',
        ),
    ];

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 240,
          pinned: true,
          actions: [
            // Sincronizado com o cache de favoritos (home, listas, coleções).
            FavoriteIconButton(wineId: wineId),
          ],
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              wine.name,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onPrimary,
              ),
            ),
            background: Container(
              color: theme.colorScheme.primary.withAlpha(30),
              child: Center(
                child: Icon(
                  Icons.wine_bar,
                  size: 100,
                  color: theme.colorScheme.primary.withAlpha(80),
                ),
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(Dimens.spacing24),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Vinícola e região
              if (wine.winery.isNotEmpty)
                Text(wine.winery, style: theme.textTheme.headlineMedium),
              if (origin.isNotEmpty) ...[
                const SizedBox(height: Dimens.spacing4),
                Text(origin, style: theme.textTheme.bodyMedium),
              ],
              const SizedBox(height: Dimens.spacing24),

              // Info chips
              if (chips.isNotEmpty) ...[
                Wrap(
                  spacing: Dimens.spacing8,
                  runSpacing: Dimens.spacing8,
                  children: chips,
                ),
                const SizedBox(height: Dimens.spacing24),
              ],

              // Por que este vinho combina com você? (oculta sem quiz/erro;
              // inclui o próprio espaçamento inferior quando visível)
              WineMatchSection(wineId: wineId),

              // Descrição (tipo de elaboração, ex.: "Varietal/100%")
              if (wine.description.isNotEmpty) ...[
                Text(
                  getString(context, 'wine_description'),
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: Dimens.spacing8),
                Text(wine.description, style: theme.textTheme.bodyLarge),
                const SizedBox(height: Dimens.spacing24),
              ],

              // Harmonização
              if (wine.harmonize.isNotEmpty) ...[
                Text(
                  getString(context, 'wine_harmonize'),
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: Dimens.spacing8),
                Wrap(
                  spacing: Dimens.spacing8,
                  runSpacing: Dimens.spacing8,
                  children: wine.harmonize
                      .map((food) => _InfoChip(
                            icon: Icons.restaurant,
                            label: translateWineLabel(
                                context, 'wine_food', food),
                          ))
                      .toList(),
                ),
                const SizedBox(height: Dimens.spacing32),
              ],

              // Avaliações
              Text(
                getString(context, 'reviews'),
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: Dimens.spacing8),
              _ReviewsSection(
                wineId: wineId,
                currentUserId: currentUserId,
                token: token,
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

class _ReviewsSection extends StatelessWidget {
  final String wineId;
  final String? currentUserId;
  final String? token;

  const _ReviewsSection({
    required this.wineId,
    this.currentUserId,
    this.token,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReviewListBloc, ReviewListState>(
      builder: (context, state) {
        return switch (state) {
          ReviewListInitial() ||
          ReviewListLoading() =>
            const Center(child: CircularProgressIndicator()),
          ReviewListError(:final message) => VinumErrorWidget(
              message: message,
              onRetry: () => context
                  .read<ReviewListBloc>()
                  .add(ReviewListStarted(wineId: wineId)),
            ),
          ReviewListLoaded(:final reviews) when reviews.isEmpty =>
            Text(getString(context, 'reviews_empty')),
          ReviewListLoaded(:final reviews) => Column(
              children: _sortForDisplay(reviews)
                  .map((r) => ReviewCard(
                        review: r,
                        wineId: wineId,
                        currentUserId: currentUserId,
                        currentToken: token,
                      ))
                  .toList(),
            ),
        };
      },
    );
  }

  List<Review> _sortForDisplay(List<Review> reviews) {
    final sorted = [...reviews];

    sorted.sort((a, b) {
      final aIsCurrentUser =
          currentUserId != null && a.usuarioId == currentUserId;
      final bIsCurrentUser =
          currentUserId != null && b.usuarioId == currentUserId;

      if (aIsCurrentUser != bIsCurrentUser) {
        return aIsCurrentUser ? -1 : 1;
      }

      return b.createdAt.compareTo(a.createdAt);
    });

    return sorted;
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  /// Quando informado, o chip é tocável (ex.: abre o conteúdo educativo) e
  /// mostra um ícone de ajuda.
  final VoidCallback? onTap;

  const _InfoChip({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final avatar = Icon(icon, size: 16, color: theme.colorScheme.primary);
    final onTap = this.onTap;

    if (onTap == null) {
      return Chip(
        avatar: avatar,
        label: Text(label, style: theme.textTheme.labelMedium),
      );
    }

    return ActionChip(
      avatar: avatar,
      onPressed: onTap,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(child: Text(label, style: theme.textTheme.labelMedium)),
          const SizedBox(width: Dimens.spacing4),
          Icon(
            Icons.help_outline,
            size: 14,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }
}
