import 'package:essentials/essentials.dart';
import 'package:flutter/material.dart';

import '../../../../core/navigation/application_route.dart';
import '../bloc/cellar_bloc.dart';
import '../bloc/cellar_event.dart';
import '../bloc/cellar_state.dart';
import '../widget/cellar_review_tile.dart';
import '../widget/cellar_summary_header.dart';

/// "Minha adega": as avaliações do usuário (`GET /v1/me/reviews`), com
/// scroll infinito e pull-to-refresh. Usada como conteúdo da aba (sem
/// Scaffold próprio).
///
/// A lista é recarregada em segundo plano sempre que o usuário volta de uma
/// tela empilhada sobre a Home (ex.: detalhe do vinho, onde a avaliação
/// pode ter sido criada, editada ou excluída).
class CellarPage extends StatelessWidget {
  const CellarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CellarBloc>(
      create: (_) =>
          ApplicationContainer.resolve<CellarBloc>()..add(CellarStarted()),
      child: const CellarView(),
    );
  }
}

class CellarView extends StatefulWidget {
  const CellarView({super.key});

  @override
  State<CellarView> createState() => _CellarViewState();
}

class _CellarViewState extends State<CellarView> {
  /// Distância do fim da lista que dispara a próxima página.
  static const double _loadMoreThreshold = 300;

  final ScrollController _scrollController = ScrollController();

  /// Rota que contém a aba (Home). A `secondaryAnimation` dela volta a
  /// `dismissed` quando a tela empilhada por cima é fechada.
  ModalRoute<dynamic>? _route;

  /// O retorno do detalhe aberto por esta lista já é tratado em
  /// [_openWine]; evita um segundo refresh.
  bool _skipNextReturn = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_maybeLoadMore);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (!identical(route, _route)) {
      _route?.secondaryAnimation?.removeStatusListener(_onCoveringRouteStatus);
      _route = route;
      _route?.secondaryAnimation?.addStatusListener(_onCoveringRouteStatus);
    }
  }

  @override
  void dispose() {
    _route?.secondaryAnimation?.removeStatusListener(_onCoveringRouteStatus);
    _scrollController
      ..removeListener(_maybeLoadMore)
      ..dispose();
    super.dispose();
  }

  /// Voltou de uma tela empilhada sobre a Home: atualiza a adega.
  void _onCoveringRouteStatus(AnimationStatus status) {
    if (status != AnimationStatus.dismissed || !mounted) return;
    if (_skipNextReturn) {
      _skipNextReturn = false;
      return;
    }
    context.read<CellarBloc>().add(CellarRefreshed());
  }

  void _maybeLoadMore() {
    if (!mounted || !_scrollController.hasClients) return;
    final state = context.read<CellarBloc>().state;
    if (state is! CellarLoaded ||
        !state.hasMore ||
        state.isLoadingMore ||
        state.isRefreshing ||
        state.loadMoreError != null) {
      return;
    }
    if (_scrollController.position.extentAfter < _loadMoreThreshold) {
      context.read<CellarBloc>().add(CellarLoadMoreRequested());
    }
  }

  Future<void> _onRefresh() async {
    final bloc = context.read<CellarBloc>();
    bloc.add(CellarRefreshed());
    try {
      await bloc.stream
          .firstWhere((s) =>
              s is! CellarLoading && !(s is CellarLoaded && s.isRefreshing))
          .timeout(const Duration(seconds: 30), onTimeout: () => bloc.state);
    } on StateError {
      // Bloc fechado antes de responder.
    }
  }

  void _retry() => context.read<CellarBloc>().add(CellarStarted());

  Future<void> _openWine(String wineId) async {
    final bloc = context.read<CellarBloc>();
    _skipNextReturn = true;
    await Navigator.pushNamed(
      context,
      ApplicationRoute.wineDetail,
      arguments: wineId,
    );
    // A avaliação pode ter sido criada/editada/excluída no detalhe.
    if (!bloc.isClosed) bloc.add(CellarRefreshed());
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CellarBloc, CellarState>(
      listenWhen: (previous, current) =>
          current is CellarSessionExpired ||
          (current is CellarLoaded &&
              (current.refreshError != null ||
                  (!current.isLoadingMore && !current.isRefreshing))),
      listener: (context, state) {
        if (state is CellarSessionExpired) {
          // Outra aba pode já ter levado ao login.
          if (_route?.isCurrent == false) return;
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
        if (state is CellarLoaded) {
          final error = state.refreshError;
          if (error != null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(content: Text(getString(context, error))),
              );
          }
          // Se a página não preenche a tela, confere de novo após o layout.
          WidgetsBinding.instance.addPostFrameCallback((_) => _maybeLoadMore());
        }
      },
      builder: (context, state) {
        return switch (state) {
          CellarInitial() ||
          CellarLoading() ||
          CellarSessionExpired() =>
            const LoadingWidget(),
          CellarEmpty() => _RefreshableMessage(
              onRefresh: _onRefresh,
              child: _MessageView(
                icon: Icons.wine_bar_outlined,
                title: getString(context, 'cellar_empty_title'),
                message: getString(context, 'cellar_empty_hint'),
              ),
            ),
          CellarError(:final message) => _RefreshableMessage(
              onRefresh: _onRefresh,
              child: _MessageView(
                icon: Icons.error_outline,
                message: getString(context, message),
                actionLabel: getString(context, 'retry'),
                actionIcon: Icons.refresh,
                onAction: _retry,
              ),
            ),
          final CellarLoaded loaded => RefreshIndicator(
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
                  if (index == 0) {
                    return CellarSummaryHeader(
                      count: loaded.items.length,
                      hasMore: loaded.hasMore,
                      averageRating: loaded.averageRating,
                    );
                  }
                  if (index == loaded.items.length + 1) {
                    return _ListFooter(
                      state: loaded,
                      onRetry: () => context
                          .read<CellarBloc>()
                          .add(CellarLoadMoreRequested()),
                    );
                  }
                  final review = loaded.items[index - 1];
                  return CellarReviewTile(
                    key: ValueKey(review.id),
                    review: review,
                    onTap: () => _openWine(review.wineId),
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
  final CellarLoaded state;
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
          getString(context, 'cellar_end_of_list'),
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
            Icon(icon, size: 56, color: theme.colorScheme.primary),
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
            const SizedBox(height: Dimens.spacing12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                height: 1.4,
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
