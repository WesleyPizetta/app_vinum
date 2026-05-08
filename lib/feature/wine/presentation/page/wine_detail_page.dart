import 'package:essentials/essentials.dart';
import 'package:flutter/material.dart';

import '../../../../feature/auth/domain/repository/auth_repository.dart';
import '../../../../feature/review/presentation/bloc/review_form_bloc.dart';
import '../../../../feature/review/presentation/bloc/review_form_state.dart';
import '../../../../feature/review/presentation/bloc/review_list_bloc.dart';
import '../../../../feature/review/presentation/bloc/review_list_event.dart';
import '../../../../feature/review/presentation/bloc/review_list_state.dart';
import '../../../../feature/review/presentation/widget/review_card.dart';
import '../../../../feature/review/presentation/widget/review_form_sheet.dart';
import '../../domain/entity/wine.dart';
import '../bloc/wine_detail_bloc.dart';
import '../bloc/wine_detail_event.dart';
import '../bloc/wine_detail_state.dart';

class WineDetailPage extends StatelessWidget {
  const WineDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final wineId = ModalRoute.of(context)!.settings.arguments as String;

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
      ],
      child: _WineDetailPageContent(wineId: wineId),
    );
  }
}

class _WineDetailPageContent extends StatelessWidget {
  final String wineId;

  const _WineDetailPageContent({required this.wineId});

  @override
  Widget build(BuildContext context) {
    final authRepo = ApplicationContainer.resolve<AuthRepository>();
    final currentUser = authRepo.getCurrentUser();
    final token = authRepo.getAccessToken();

    return BlocListener<ReviewFormBloc, ReviewFormState>(
      listener: (context, state) {
        if (state is ReviewFormSuccess) {
          context
              .read<ReviewListBloc>()
              .add(ReviewListStarted(wineId: wineId));
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
                  currentUserId: currentUser?.id,
                  token: token,
                ),
              WineDetailError(:final message) => VinumErrorWidget(
                  message: message,
                  onRetry: () => context
                      .read<WineDetailBloc>()
                      .add(WineDetailStarted(wineId: wineId)),
                ),
            };
          },
        ),
        floatingActionButton: token != null && currentUser != null
            ? FloatingActionButton(
                onPressed: () => showReviewFormSheet(
                  context,
                  wineId: wineId,
                  usuarioId: currentUser.id,
                  token: token,
                ),
                child: const Icon(Icons.rate_review_outlined),
              )
            : null,
      ),
    );
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

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 240,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              wine.name,
              style: TextStyle(
                fontFamily: 'Amarante',
                fontSize: 16,
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
              Text(wine.winery, style: theme.textTheme.headlineMedium),
              const SizedBox(height: Dimens.spacing4),
              Text(
                '${wine.region}, ${wine.country}',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: Dimens.spacing24),

              // Info chips
              Wrap(
                spacing: Dimens.spacing8,
                runSpacing: Dimens.spacing8,
                children: [
                  _InfoChip(icon: Icons.grass, label: wine.grape),
                  _InfoChip(
                      icon: Icons.calendar_today, label: '${wine.vintage}'),
                  _InfoChip(
                      icon: Icons.star_rounded,
                      label: wine.rating.toStringAsFixed(1)),
                ],
              ),
              const SizedBox(height: Dimens.spacing24),

              // Descrição
              Text(
                getString(context, 'wine_description'),
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: Dimens.spacing8),
              Text(wine.description, style: theme.textTheme.bodyLarge),
              const SizedBox(height: Dimens.spacing32),

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
          ReviewListInitial() || ReviewListLoading() =>
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
              children: reviews
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
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Chip(
      avatar: Icon(icon, size: 16, color: theme.colorScheme.primary),
      label: Text(label, style: theme.textTheme.labelMedium),
    );
  }
}
