import '../../domain/entity/favorite_wine.dart';

sealed class FavoritesListState {}

class FavoritesListInitial extends FavoritesListState {}

/// Carregando a primeira página (tela inteira).
class FavoritesListLoading extends FavoritesListState {}

class FavoritesListLoaded extends FavoritesListState {
  final List<FavoriteWine> items;
  final bool hasMore;

  /// Offset da próxima página (válido quando [hasMore]). Ajustado quando
  /// itens são removidos, para não pular vinhos no servidor.
  final int nextOffset;

  /// Total de favoritos.
  final int total;

  /// Carregando a próxima página (indicador no rodapé).
  final bool isLoadingMore;

  /// Chave i18n do erro ao carregar mais (rodapé com "tentar novamente").
  final String? loadMoreError;

  /// Pull-to-refresh em andamento.
  final bool isRefreshing;

  /// Chave i18n do erro no pull-to-refresh (itens atuais preservados;
  /// SnackBar). Transitório: não é copiado por [copyWith].
  final String? refreshError;

  /// Chave i18n de falha ao desfavoritar (SnackBar). Transitório: não é
  /// copiado por [copyWith].
  final String? actionError;

  FavoritesListLoaded({
    required this.items,
    required this.hasMore,
    required this.nextOffset,
    required this.total,
    this.isLoadingMore = false,
    this.loadMoreError,
    this.isRefreshing = false,
    this.refreshError,
    this.actionError,
  });

  FavoritesListLoaded copyWith({
    List<FavoriteWine>? items,
    bool? hasMore,
    int? nextOffset,
    int? total,
    bool? isLoadingMore,
    String? loadMoreError,
    bool clearLoadMoreError = false,
    bool? isRefreshing,
    String? refreshError,
    String? actionError,
  }) {
    return FavoritesListLoaded(
      items: items ?? this.items,
      hasMore: hasMore ?? this.hasMore,
      nextOffset: nextOffset ?? this.nextOffset,
      total: total ?? this.total,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      loadMoreError:
          clearLoadMoreError ? null : (loadMoreError ?? this.loadMoreError),
      isRefreshing: isRefreshing ?? this.isRefreshing,
      refreshError: refreshError,
      actionError: actionError,
    );
  }
}

/// O usuário não tem favoritos.
class FavoritesListEmpty extends FavoritesListState {}

/// Erro ao carregar a primeira página.
class FavoritesListError extends FavoritesListState {
  /// Chave i18n.
  final String message;

  FavoritesListError({required this.message});
}

/// 401: logout já executado, a tela volta ao login.
class FavoritesListSessionExpired extends FavoritesListState {
  /// Chave i18n.
  final String message;

  FavoritesListSessionExpired({required this.message});
}
