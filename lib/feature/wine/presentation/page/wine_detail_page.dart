import 'package:essentials/essentials.dart';
import 'package:flutter/material.dart';

import '../../domain/entity/wine.dart';
import '../bloc/wine_detail_bloc.dart';
import '../bloc/wine_detail_event.dart';
import '../bloc/wine_detail_state.dart';

class WineDetailPage extends StatelessWidget {
  const WineDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final wineId = ModalRoute.of(context)!.settings.arguments as String;

    return BlocProvider(
      create: (_) => ApplicationContainer.resolve<WineDetailBloc>()
        ..add(WineDetailStarted(wineId: wineId)),
      child: Scaffold(
        body: BlocBuilder<WineDetailBloc, WineDetailState>(
          builder: (context, state) {
            return switch (state) {
              WineDetailInitial() => const SizedBox.shrink(),
              WineDetailLoading() => const LoadingWidget(),
              WineDetailLoaded(:final wine) => _WineDetailContent(wine: wine),
              WineDetailError(:final message) => VinumErrorWidget(
                  message: message,
                  onRetry: () => context
                      .read<WineDetailBloc>()
                      .add(WineDetailStarted(wineId: wineId)),
                ),
            };
          },
        ),
      ),
    );
  }
}

class _WineDetailContent extends StatelessWidget {
  final Wine wine;

  const _WineDetailContent({required this.wine});

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
                  _InfoChip(
                    icon: Icons.grass,
                    label: wine.grape,
                  ),
                  _InfoChip(
                    icon: Icons.calendar_today,
                    label: '${wine.vintage}',
                  ),
                  _InfoChip(
                    icon: Icons.star_rounded,
                    label: wine.rating.toStringAsFixed(1),
                  ),
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
            ]),
          ),
        ),
      ],
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
