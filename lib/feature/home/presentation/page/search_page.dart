import 'package:essentials/essentials.dart';
import 'package:flutter/material.dart';

import '../../../../core/navigation/application_route.dart';
import '../../domain/entity/food_category.dart';
import '../bloc/search_bloc.dart';
import '../bloc/search_event.dart';
import '../bloc/search_state.dart';
import '../widget/food_category_labels.dart';
import '../widget/food_wine_list_tile.dart';

/// Busca por vinhos e pratos (`GET /v1/me/search`): campo com foco
/// automático e debounce, chips das comidas reconhecidas (abrem a lista por
/// comida) e lista de vinhos com scroll infinito.
///
/// Aberta com [SearchPage.route] (sem rota nomeada); cria o próprio
/// [SearchBloc] via DI.
class SearchPage extends StatelessWidget {
  /// Texto inicial (buscado imediatamente quando informado).
  final String initialQuery;

  const SearchPage({super.key, this.initialQuery = ''});

  static Route<void> route({String initialQuery = ''}) =>
      MaterialPageRoute<void>(
        builder: (_) => SearchPage(initialQuery: initialQuery),
      );

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SearchBloc>(
      create: (_) {
        final bloc = ApplicationContainer.resolve<SearchBloc>();
        if (initialQuery.trim().isNotEmpty) {
          bloc.add(SearchSubmitted(initialQuery));
        }
        return bloc;
      },
      child: Scaffold(
        appBar: VinumAppBar(title: getString(context, 'search_title')),
        body: _SearchView(initialQuery: initialQuery),
      ),
    );
  }
}

class _SearchView extends StatefulWidget {
  final String initialQuery;

  const _SearchView({required this.initialQuery});

  @override
  State<_SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<_SearchView> {
  /// Distância do fim da lista que dispara a próxima página.
  static const double _loadMoreThreshold = 300;

  late final TextEditingController _textController =
      TextEditingController(text: widget.initialQuery);
  final FocusNode _focusNode = FocusNode();
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
    _focusNode.dispose();
    _textController.dispose();
    super.dispose();
  }

  /// Dispara "carregar mais" perto do fim (o bloc também se protege).
  void _maybeLoadMore() {
    if (!mounted || !_scrollController.hasClients) return;
    final bloc = context.read<SearchBloc>();
    final state = bloc.state;
    if (state is! SearchLoaded ||
        state.query != bloc.query ||
        !state.hasMore ||
        state.isLoadingMore ||
        state.loadMoreError != null) {
      return;
    }
    if (_scrollController.position.extentAfter < _loadMoreThreshold) {
      bloc.add(SearchLoadMoreRequested());
    }
  }

  void _onChanged(String text) =>
      context.read<SearchBloc>().add(SearchQueryChanged(text));

  void _onSubmitted(String text) =>
      context.read<SearchBloc>().add(SearchSubmitted(text));

  void _clear() {
    _textController.clear();
    context.read<SearchBloc>().add(SearchQueryChanged(''));
    _focusNode.requestFocus();
  }

  void _retry() => context.read<SearchBloc>().add(SearchRetried());

  Future<void> _openQuiz() async {
    await Navigator.pushNamed(context, ApplicationRoute.onboarding);
    if (mounted) _retry();
  }

  void _openWine(String wineId) {
    _focusNode.unfocus();
    Navigator.pushNamed(
      context,
      ApplicationRoute.wineDetail,
      arguments: wineId,
    );
  }

  void _openFood(FoodCategory food) {
    _focusNode.unfocus();
    // Mesmo fluxo dos cards de refeição da home.
    Navigator.pushNamed(
      context,
      ApplicationRoute.foodWines,
      arguments: food,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Dimens.spacing16,
            Dimens.spacing16,
            Dimens.spacing16,
            Dimens.spacing8,
          ),
          child: _SearchField(
            controller: _textController,
            focusNode: _focusNode,
            onChanged: _onChanged,
            onSubmitted: _onSubmitted,
            onClear: _clear,
          ),
        ),
        Expanded(
          child: BlocConsumer<SearchBloc, SearchState>(
            listenWhen: (previous, current) =>
                current is SearchSessionExpired ||
                (current is SearchLoaded &&
                    (current.favoriteErrorMessage != null ||
                        !current.isLoadingMore)),
            listener: _onStateChanged,
            builder: (context, state) {
              final foods = switch (state) {
                SearchLoaded(:final foods) => foods,
                SearchEmpty(:final foods) => foods,
                _ => const <FoodCategory>[],
              };
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (foods.isNotEmpty)
                    _FoodChipsBar(foods: foods, onTap: _openFood),
                  Expanded(child: _buildContent(context, state)),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  void _onStateChanged(BuildContext context, SearchState state) {
    if (state is SearchSessionExpired) {
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
    if (state is SearchLoaded) {
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
      // Se a página não preenche a tela, o scroll nunca chega perto do
      // fim: confere de novo depois do layout.
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeLoadMore());
    }
  }

  Widget _buildContent(BuildContext context, SearchState state) {
    return switch (state) {
      SearchIdle() => _MessageView(
          icon: Icons.search,
          message: getString(context, 'search_idle_hint'),
        ),
      SearchQueryTooShort() => _MessageView(
          icon: Icons.keyboard_outlined,
          message: getString(context, 'search_min_letters'),
        ),
      SearchLoading() || SearchSessionExpired() => const LoadingWidget(),
      SearchEmpty(:final query, :final foods) => _MessageView(
          icon: Icons.wine_bar_outlined,
          message: getString(
            context,
            foods.isEmpty ? 'search_empty' : 'search_empty_with_foods',
          ).replaceAll('{query}', query),
        ),
      SearchError(:final message) => _MessageView(
          icon: Icons.error_outline,
          message: getString(context, message),
          actionLabel: getString(context, 'retry'),
          actionIcon: Icons.refresh,
          onAction: _retry,
        ),
      SearchOnboardingRequired() => _MessageView(
          icon: Icons.quiz_outlined,
          message: getString(context, 'search_onboarding_required'),
          actionLabel: getString(context, 'home_recommendations_take_quiz'),
          actionIcon: Icons.arrow_forward,
          onAction: _openQuiz,
        ),
      final SearchLoaded loaded => ListView.separated(
          controller: _scrollController,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(
            Dimens.spacing16,
            Dimens.spacing8,
            Dimens.spacing16,
            Dimens.spacing16,
          ),
          itemCount: loaded.items.length + 1,
          separatorBuilder: (_, __) => const SizedBox(height: Dimens.spacing12),
          itemBuilder: (context, index) {
            if (index == loaded.items.length) {
              return _ListFooter(
                state: loaded,
                onRetry: () => context
                    .read<SearchBloc>()
                    .add(SearchLoadMoreRequested()),
              );
            }
            final wine = loaded.items[index];
            return FoodWineListTile(
              key: ValueKey(wine.id),
              wine: wine,
              onTap: () => _openWine(wine.id),
              onFavoriteToggle: () => context
                  .read<SearchBloc>()
                  .add(SearchFavoriteToggled(wine.id)),
            );
          },
        ),
    };
  }
}

/// Campo de busca com o mesmo visual do campo da home.
class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;

  const _SearchField({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(Dimens.radiusXLarge),
      borderSide: BorderSide.none,
    );

    return TextField(
      controller: controller,
      focusNode: focusNode,
      autofocus: true,
      textInputAction: TextInputAction.search,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        hintText: getString(context, 'search_wine_food_placeholder'),
        hintStyle: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
        ),
        filled: true,
        fillColor: theme.colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Dimens.spacing16,
          vertical: Dimens.spacing12,
        ),
        border: border,
        enabledBorder: border,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Dimens.radiusXLarge),
          borderSide: BorderSide(
            color: theme.colorScheme.primary.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        prefixIcon: Icon(
          Icons.search,
          color: theme.colorScheme.primary,
        ),
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) => value.text.isEmpty
              ? const SizedBox.shrink()
              : IconButton(
                  tooltip: getString(context, 'search_clear'),
                  onPressed: onClear,
                  icon: const Icon(Icons.close),
                ),
        ),
      ),
    );
  }
}

/// Chips das comidas reconhecidas no texto (ex.: "picanha" -> Carnes).
class _FoodChipsBar extends StatelessWidget {
  final List<FoodCategory> foods;
  final ValueChanged<FoodCategory> onTap;

  const _FoodChipsBar({required this.foods, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: Dimens.spacing4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Dimens.spacing16),
            child: Text(
              getString(context, 'search_foods_title'),
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
          const SizedBox(height: Dimens.spacing4),
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding:
                  const EdgeInsets.symmetric(horizontal: Dimens.spacing16),
              itemCount: foods.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: Dimens.spacing8),
              itemBuilder: (context, index) {
                final food = foods[index];
                return Center(
                  child: ActionChip(
                    avatar: Icon(
                      Icons.restaurant,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    label: Text(
                      getString(context, food.searchLabelKey),
                      style: theme.textTheme.labelMedium,
                    ),
                    onPressed: () => onTap(food),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Rodapé da lista: carregando / erro com "tentar novamente" / fim.
class _ListFooter extends StatelessWidget {
  final SearchLoaded state;
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
          getString(context, 'search_end_of_list'),
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

    // Rolável para não estourar com o teclado aberto.
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.all(Dimens.spacing24),
      child: Column(
        children: [
          const SizedBox(height: Dimens.spacing24),
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
    );
  }
}
