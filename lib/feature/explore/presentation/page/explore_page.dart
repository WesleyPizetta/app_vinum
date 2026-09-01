import 'package:essentials/essentials.dart';
import 'package:flutter/material.dart';

import '../../../../core/navigation/application_route.dart';
import '../../../wine/domain/entity/wine.dart';
import '../../../wine/presentation/bloc/wine_list_bloc.dart';
import '../../../wine/presentation/bloc/wine_list_event.dart';
import '../../../wine/presentation/bloc/wine_list_state.dart';

class ExplorePage extends StatelessWidget {
  const ExplorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ApplicationContainer.resolve<WineListBloc>()
        ..add(WineListStarted()),
      child: const ExploreView(),
    );
  }
}

class ExploreView extends StatelessWidget {
  const ExploreView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WineListBloc, WineListState>(
      builder: (context, state) {
        return switch (state) {
          WineListInitial() => const SizedBox.shrink(),
          WineListLoading() => const LoadingWidget(),
          WineListLoaded(:final wines) => _ExploreWineList(wines: wines),
          WineListError(:final message) => VinumErrorWidget(
              message: message,
              onRetry: () =>
                  context.read<WineListBloc>().add(WineListStarted()),
            ),
        };
      },
    );
  }
}

class _ExploreWineList extends StatelessWidget {
  final List<Wine> wines;

  const _ExploreWineList({required this.wines});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(Dimens.spacing16),
      itemCount: wines.length,
      separatorBuilder: (_, __) => const SizedBox(height: Dimens.spacing12),
      itemBuilder: (context, index) => _WineCard(wine: wines[index]),
    );
  }
}

class _WineCard extends StatelessWidget {
  final Wine wine;

  const _WineCard({required this.wine});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(Dimens.radiusLarge),
        onTap: () => Navigator.pushNamed(
          context,
          ApplicationRoute.wineDetail,
          arguments: wine.id,
        ),
        child: Padding(
          padding: const EdgeInsets.all(Dimens.spacing16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 80,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withAlpha(25),
                  borderRadius: BorderRadius.circular(Dimens.radiusMedium),
                ),
                child: Icon(
                  Icons.wine_bar,
                  color: theme.colorScheme.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: Dimens.spacing16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      wine.name,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: Dimens.spacing4),
                    Text(
                      '${wine.winery} • ${wine.vintage}',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: Dimens.spacing4),
                    Row(
                      children: [
                        Icon(
                          Icons.star_rounded,
                          size: Dimens.iconSmall,
                          color: theme.colorScheme.secondary,
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
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
