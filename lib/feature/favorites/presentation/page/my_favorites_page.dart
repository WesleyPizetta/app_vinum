import 'package:essentials/essentials.dart';
import 'package:flutter/material.dart';

import '../../../../core/navigation/application_route.dart';
import '../bloc/favorites_list_bloc.dart';
import '../bloc/favorites_list_event.dart';
import '../bloc/favorites_list_state.dart';
import '../widget/favorite_wine_list_tile.dart';

/// "Meus favoritos": lista paginada (scroll infinito) com pull-to-refresh.
/// Usada como conteúdo da aba Coleções (sem Scaffold próprio).
class MyFavoritesPage extends StatelessWidget {
  const MyFavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<FavoritesListBloc>(
      create: (_) => ApplicationContainer.resolve<FavoritesListBloc>()
        ..add(FavoritesListStarted()),
      child: const _MyFavoritesView(),
    );
  }
}

class _MyFavoritesView extends StatefulWidget {
  const _MyFavoritesView();

  @override
  State<_MyFavoritesView> createState() => _MyFavoritesViewState();
}

class _MyFavoritesViewState extends State<_MyFavoritesView> {
  /// Distância do fim da lista que dispara a próxima página.
  static const double _loadMoreThreshold = 300;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_maybeLoadMore);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_maybeLoadMore)
      ..dispose();
    super.dispose();
  }

  void _maybeLoadMore() {
    if (!mounted || !_scrollController.hasClients) return;
    final state = context.read<FavoritesListBloc>().state;
    if (state is! FavoritesListLoaded ||
        !state.hasMore ||
        state.isLoadingMore ||
        state.isRefreshing ||
        state.loadMoreError != null) {
      return;
    }
    if (_scrollController.position.extentAfter < _loadMoreThreshold) {
      context.read<FavoritesListBloc>().add(FavoritesListLoadMoreRequested());
    }
  }

  Future<void> _onRefresh() async {
    final bloc = context.read<FavoritesListBloc>();
    bloc.add(FavoritesListRefreshed());
    try {
      await bloc.stream
          .firstWhere((s) =>
              s is! FavoritesListLoading &&
              !(s is FavoritesListLoaded && s.isRefreshing))
          .timeout(const Duration(seconds: 30), onTimeout: () => bloc.state);
    } on StateError {
      // Bloc fechado antes de responder.
    }
  }

  void _retry() =>
      context.read<FavoritesListBloc>().add(FavoritesListStarted());

  void _openWine(String wineId) {
    Navigator.pushNamed(
      context,
      ApplicationRoute.wineDetail,
      arguments: wineId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FavoritesListBloc, FavoritesListState>(
      listenWhen: (previous, current) =>
          current is FavoritesListSessionExpired ||
          (current is FavoritesListLoaded &&
              (current.refreshError != null ||
                  current.actionError != null ||
                  (!current.isLoadingMore && !current.isRefreshing))),
      listener: (context, state) {
        if (state is FavoritesListSessionExpired) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(getString(context, state.message))),
          );
          Navigator.pushNamedAndRemoveUntil(
            context,
            ApplicationRoute.login,
            (_) => false,
          );
          return;
        }
        if (state is FavoritesListLoaded) {
          final error = state.actionError ?? state.refreshError;
          if (error != null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(content: Text(getString(context, error))),
              );
          }
          // Se a página não preenche a tela, confere de novo após o layout.
          WidgetsBinding.instance
              .addPostFrameCallback((_) => _maybeLoadMore());
        }
      },
      builder: (context, state) {
        return switch (state) {
          FavoritesListInitial() ||
          FavoritesListLoading() ||
          FavoritesListSessionExpired() =>
            const LoadingWidget(),
          FavoritesListEmpty() => _RefreshableMessage(
              onRefresh: _onRefresh,
              child: _MessageView(
                icon: Icons.bookmark_outline,
                title: getString(context, 'favorites_title'),
                message: getString(context, 'favorites_empty'),
              ),
            ),
          FavoritesListError(:final message) => _RefreshableMessage(
              onRefresh: _onRefresh,
              child: _MessageView(
                icon: Icons.error_outline,
                message: getString(context, message),
                actionLabel: getString(context, 'retry'),
                actionIcon: Icons.refresh,
                onAction: _retry,
              ),
            ),
          final FavoritesListLoaded loaded => RefreshIndicator(
              onRefresh: _onRefresh,
              child: ListView.separated(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(Dimens.spacing16),
                // Cabeçalho + itens + rodapé.
                itemCount: loaded.items.length + 2,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: Dimens.spacing12),
                itemBuilder: (context, index) {
                  if (index == 0) return _Header(total: loaded.total);
                  if (index == loaded.items.length + 1) {
                    return _ListFooter(
                      state: loaded,
                      onRetry: () => context
                          .read<FavoritesListBloc>()
                          .add(FavoritesListLoadMoreRequested()),
                    );
                  }
                  final favorite = loaded.items[index - 1];
                  return FavoriteWineListTile(
                    key: ValueKey(favorite.id),
                    favorite: favorite,
                    onTap: () => _openWine(favorite.id),
                    onRemove: () => context
                        .read<FavoritesListBloc>()
                        .add(FavoritesListRemoveRequested(favorite.id)),
                  );
                },
              ),
            ),
        };
      },
    );
  }
}

class _Header extends StatelessWidget {
  final int total;

  const _Header({required this.total});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final count = total == 1
        ? getString(context, 'favorites_count_one')
        : getString(context, 'favorites_count').replaceAll('{count}', '$total');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Expanded(
          child: Text(
            getString(context, 'favorites_title'),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        Text(
          count,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}

/// Rodapé da lista: carregando / erro com "tentar novamente" / fim.
class _ListFooter extends StatelessWidget {
  final FavoritesListLoaded state;
  final VoidCallback onRetry;

  const _ListFooter({required this.state, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (state.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: Dimens.spacing16),
        child: Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
        ),
      );
    }

    final error = state.loadMoreError;
    if (error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: Dimens.spacing8),
        child: Column(
          children: [
            Text(
              getString(context, error),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: Dimens.spacing8),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(getString(context, 'retry')),
            ),
          ],
        ),
      );
    }

    if (!state.hasMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: Dimens.spacing16),
        child: Text(
          getString(context, 'favorites_end_of_list'),
          textAlign: TextAlign.center,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      );
    }

    // Ainda há páginas: espaço para o scroll alcançar o gatilho.
    return const SizedBox(height: Dimens.spacing48);
  }
}

/// Permite pull-to-refresh também nos estados vazio/erro.
class _RefreshableMessage extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final Widget child;

  const _RefreshableMessage({required this.onRefresh, required this.child});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _MessageView extends StatelessWidget {
  final IconData icon;
  final String? title;
  final String message;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;

  const _MessageView({
    required this.icon,
    this.title,
    required this.message,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Dimens.spacing24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: theme.colorScheme.primary),
            if (title != null) ...[
              const SizedBox(height: Dimens.spacing16),
              Text(
                title!,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
            const SizedBox(height: Dimens.spacing16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: Dimens.spacing24),
              OutlinedButton.icon(
                onPressed: onAction,
                icon: Icon(actionIcon ?? Icons.arrow_forward),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
