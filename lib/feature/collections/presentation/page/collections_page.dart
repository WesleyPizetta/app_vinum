import 'package:essentials/essentials.dart';
import 'package:flutter/material.dart';

import '../../domain/entity/collection_item.dart';
import '../bloc/collections_bloc.dart';
import '../bloc/collections_event.dart';
import '../bloc/collections_state.dart';

class CollectionsPage extends StatelessWidget {
  const CollectionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ApplicationContainer.resolve<CollectionsBloc>()
        ..add(CollectionsStarted()),
      child: const CollectionsView(),
    );
  }
}

class CollectionsView extends StatelessWidget {
  const CollectionsView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CollectionsBloc, CollectionsState>(
      builder: (context, state) {
        return switch (state) {
          CollectionsInitial() => const SizedBox.shrink(),
          CollectionsLoading() => const LoadingWidget(),
          CollectionsLoaded(:final collections) =>
            _CollectionsList(collections: collections),
          CollectionsError(:final message) => VinumErrorWidget(
              message: message,
              onRetry: () =>
                  context.read<CollectionsBloc>().add(CollectionsStarted()),
            ),
        };
      },
    );
  }
}

class _CollectionsList extends StatelessWidget {
  final List<CollectionItem> collections;

  const _CollectionsList({required this.collections});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView.separated(
      padding: const EdgeInsets.all(Dimens.spacing16),
      itemCount: collections.length,
      separatorBuilder: (_, __) => const SizedBox(height: Dimens.spacing12),
      itemBuilder: (context, index) {
        final collection = collections[index];
        return Card(
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: Dimens.spacing20,
              vertical: Dimens.spacing8,
            ),
            leading: CircleAvatar(
              backgroundColor:
                  theme.colorScheme.primary.withValues(alpha: 0.12),
              child: Icon(
                collection.icon,
                color: theme.colorScheme.primary,
              ),
            ),
            title: Text(
              collection.title,
              style: theme.textTheme.titleMedium,
            ),
            trailing: Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            onTap: () {},
          ),
        );
      },
    );
  }
}
