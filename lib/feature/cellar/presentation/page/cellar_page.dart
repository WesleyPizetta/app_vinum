import 'package:essentials/essentials.dart';
import 'package:flutter/material.dart';

import '../bloc/cellar_bloc.dart';
import '../bloc/cellar_event.dart';
import '../bloc/cellar_state.dart';

class CellarPage extends StatelessWidget {
  const CellarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ApplicationContainer.resolve<CellarBloc>()
        ..add(CellarStarted()),
      child: const CellarView(),
    );
  }
}

class CellarView extends StatelessWidget {
  const CellarView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CellarBloc, CellarState>(
      builder: (context, state) {
        return switch (state) {
          CellarInitial() => const SizedBox.shrink(),
          CellarLoading() => const LoadingWidget(),
          CellarLoaded(:final items) => _CellarContent(itemsCount: items.length),
          CellarError(:final message) => VinumErrorWidget(
              message: message,
              onRetry: () => context.read<CellarBloc>().add(CellarStarted()),
            ),
        };
      },
    );
  }
}

class _CellarContent extends StatelessWidget {
  final int itemsCount;

  const _CellarContent({required this.itemsCount});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(Dimens.spacing24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            color: theme.colorScheme.surface,
            child: Padding(
              padding: const EdgeInsets.all(Dimens.spacing20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: Dimens.radiusLarge,
                    backgroundColor:
                        theme.colorScheme.primary.withValues(alpha: 0.15),
                    child: Icon(
                      Icons.wine_bar,
                      color: theme.colorScheme.primary,
                      size: Dimens.iconLarge,
                    ),
                  ),
                  const SizedBox(width: Dimens.spacing16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          getString(context, 'nav_cellar'),
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: Dimens.spacing4),
                        Text(
                          '$itemsCount rótulos salvos na sua adega',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Dimens.spacing48),
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: Dimens.spacing16),
          Text(
            'Sua adega está vazia',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: Dimens.spacing8),
          Text(
            'Explore os vinhos do catálogo e salve os seus favoritos aqui.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
