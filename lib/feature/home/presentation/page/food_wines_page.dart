import 'package:essentials/essentials.dart';
import 'package:flutter/material.dart';

import '../../../../core/navigation/application_route.dart';
import '../../domain/entity/food_category.dart';
import '../bloc/food_wines_bloc.dart';
import '../bloc/food_wines_event.dart';
import '../bloc/food_wines_state.dart';
import '../widget/food_category_labels.dart';
import '../widget/food_wine_list_tile.dart';

/// Vinhos recomendados para uma categoria de comida, com scroll infinito.
///
/// Rota: [ApplicationRoute.foodWines], `arguments`: [FoodCategory] (ou o
/// valor da API como `String`, ex.: `'meat'`).
class FoodWinesPage extends StatelessWidget {
  const FoodWinesPage({super.key});

  static FoodCategory? _resolveFood(Object? arguments) {
    if (arguments is FoodCategory) return arguments;
    if (arguments is String) return FoodCategory.fromApiValue(arguments);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final food = _resolveFood(ModalRoute.of(context)?.settings.arguments);
    final title = getString(
      context,
      food?.winesTitleKey ?? 'food_wines_title_default',
    );

    if (food == null) {
      return Scaffold(
        appBar: VinumAppBar(title: title),
        body: _MessageView(
          icon: Icons.error_outline,
          message: getString(context, 'food_wines_error_invalid_category'),
        ),
      );
    }

    return BlocProvider<FoodWinesBloc>(
      create: (_) => ApplicationContainer.resolve<FoodWinesBloc>()
        ..add(FoodWinesStarted(food)),
      child: Scaffold(
        appBar: VinumAppBar(title: title),
        body: _FoodWinesView(food: food),
      ),
    );
  }
}

class _FoodWinesView extends StatefulWidget {
  final FoodCategory food;

  const _FoodWinesView({required this.food});

  @override
  State<_FoodWinesView> createState() => _FoodWinesViewState();
}

class _FoodWinesViewState extends State<_FoodWinesView> {
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

  /// Dispara "carregar mais" perto do fim. O bloc também se protege, mas
  /// aqui evitamos eventos desnecessários e o re-disparo automático depois
  /// de um erro (o usuário usa o botão do rodapé).
  void _maybeLoadMore() {
    if (!mounted || !_scrollController.hasClients) return;
    final state = context.read<FoodWinesBloc>().state;
    if (state is! FoodWinesLoaded ||
        !state.hasMore ||
        state.isLoadingMore ||
        state.isRefreshing ||
        state.loadMoreError != null) {
      return;
    }
    if (_scrollController.position.extentAfter < _loadMoreThreshold) {
      context.read<FoodWinesBloc>().add(FoodWinesLoadMoreRequested());
    }
  }

  Future<void> _onRefresh() async {
    final bloc = context.read<FoodWinesBloc>();
    bloc.add(FoodWinesRefreshed());
    // Espera o refresh terminar para fechar o indicador.
    try {
      await bloc.stream
          .firstWhere((s) =>
              s is! FoodWinesLoading &&
              !(s is FoodWinesLoaded && s.isRefreshing))
          .timeout(const Duration(seconds: 30), onTimeout: () => bloc.state);
    } on StateError {
      // Bloc fechado antes de responder (página saiu da pilha).
    }
  }

  void _retry() =>
      context.read<FoodWinesBloc>().add(FoodWinesStarted(widget.food));

  Future<void> _openQuiz() async {
    await Navigator.pushNamed(context, ApplicationRoute.onboarding);
    if (mounted) _retry();
  }

  void _openWine(String wineId) {
    Navigator.pushNamed(
      context,
      ApplicationRoute.wineDetail,
      arguments: wineId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FoodWinesBloc, FoodWinesState>(
      listenWhen: (previous, current) =>
          current is FoodWinesSessionExpired ||
          (current is FoodWinesLoaded &&
              (current.refreshError != null ||
                  current.favoriteErrorMessage != null ||
                  (!current.isLoadingMore && !current.isRefreshing))),
      listener: (context, state) {
        if (state is FoodWinesSessionExpired) {
          // Mesmo fluxo da home: logout já feito pelo bloc.
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
        if (state is FoodWinesLoaded) {
          final favoriteError = state.favoriteErrorMessage;
          if (favoriteError != null) {
            // Falha ao favoritar (o ícone já voltou ao estado anterior).
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(content: Text(getString(context, favoriteError))),
              );
            return;
          }
          if (state.refreshError != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(getString(context, state.refreshError!)),
              ),
            );
          }
          // Se a página não preenche a tela, o scroll nunca chega perto do
          // fim: confere de novo depois do layout.
          WidgetsBinding.instance
              .addPostFrameCallback((_) => _maybeLoadMore());
        }
      },
      builder: (context, state) {
        return switch (state) {
          FoodWinesInitial() ||
          FoodWinesLoading() ||
          FoodWinesSessionExpired() =>
            const LoadingWidget(),
          FoodWinesEmpty() => _RefreshableMessage(
              onRefresh: _onRefresh,
              child: _MessageView(
                icon: Icons.wine_bar_outlined,
                message: getString(context, 'food_wines_empty'),
                actionLabel: getString(context, 'retry'),
                actionIcon: Icons.refresh,
                onAction: _retry,
              ),
            ),
          FoodWinesError(:final message) => _RefreshableMessage(
              onRefresh: _onRefresh,
              child: _MessageView(
                icon: Icons.error_outline,
                message: getString(context, message),
                actionLabel: getString(context, 'retry'),
                actionIcon: Icons.refresh,
                onAction: _retry,
              ),
            ),
          FoodWinesOnboardingRequired() => _MessageView(
              icon: Icons.quiz_outlined,
              message: getString(context, 'food_wines_onboarding_required'),
              actionLabel: getString(context, 'home_recommendations_take_quiz'),
              actionIcon: Icons.arrow_forward,
              onAction: _openQuiz,
            ),
          final FoodWinesLoaded loaded => RefreshIndicator(
              onRefresh: _onRefresh,
              child: ListView.separated(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(Dimens.spacing16),
                itemCount: loaded.items.length + 1,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: Dimens.spacing12),
                itemBuilder: (context, index) {
                  if (index == loaded.items.length) {
                    return _ListFooter(
                      state: loaded,
                      onRetry: () => context
                          .read<FoodWinesBloc>()
                          .add(FoodWinesLoadMoreRequested()),
                    );
                  }
                  final wine = loaded.items[index];
                  return FoodWineListTile(
                    key: ValueKey(wine.id),
                    wine: wine,
                    onTap: () => _openWine(wine.id),
                    onFavoriteToggle: () => context
                        .read<FoodWinesBloc>()
                        .add(FoodWinesFavoriteToggled(wine.id)),
                  );
                },
              ),
            ),
        };
      },
    );
  }
}

/// Rodapé da lista: carregando / erro com "tentar novamente" / fim.
class _ListFooter extends StatelessWidget {
  final FoodWinesLoaded state;
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
          getString(context, 'food_wines_end_of_list'),
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
  final String message;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;

  const _MessageView({
    required this.icon,
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
