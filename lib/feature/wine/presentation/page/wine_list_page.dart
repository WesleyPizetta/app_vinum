import 'package:essentials/essentials.dart';
import 'package:flutter/material.dart';

import '../../../../core/navigation/application_route.dart';
import '../../domain/entity/wine.dart';
import '../bloc/wine_list_bloc.dart';
import '../bloc/wine_list_event.dart';
import '../bloc/wine_list_state.dart';

class WineListPage extends StatelessWidget {
  const WineListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ApplicationContainer.resolve<WineListBloc>()
        ..add(WineListStarted()),
      child: Scaffold(
        appBar: VinumAppBar(
          title: getString(context, 'wine_catalog'),
          showBackButton: true,
        ),
        body: BlocBuilder<WineListBloc, WineListState>(
          builder: (context, state) {
            return switch (state) {
              WineListInitial() => const SizedBox.shrink(),
              WineListLoading() => const LoadingWidget(),
              WineListLoaded(:final wines) => _WineList(wines: wines),
              WineListError(:final message) => VinumErrorWidget(
                  message: message,
                  onRetry: () =>
                      context.read<WineListBloc>().add(WineListStarted()),
                ),
            };
          },
        ),
      ),
    );
  }
}

class _WineList extends StatelessWidget {
  final List<Wine> wines;

  const _WineList({required this.wines});

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
              // Placeholder para imagem
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: Dimens.spacing4),
                    Text(
                      '${wine.winery} · ${wine.region}',
                      style: theme.textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: Dimens.spacing4),
                    Row(
                      children: [
                        Text(
                          wine.grape,
                          style: theme.textTheme.labelMedium,
                        ),
                        const Spacer(),
                        Icon(
                          Icons.star_rounded,
                          size: 16,
                          color: theme.colorScheme.secondary,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          wine.rating.toStringAsFixed(1),
                          style: theme.textTheme.labelMedium,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Dimens.spacing8),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.primary.withAlpha(120),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
