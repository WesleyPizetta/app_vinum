import '../../domain/entity/recommended_wine.dart';

sealed class FoodWinesState {}

class FoodWinesInitial extends FoodWinesState {}

/// Carregando a primeira página (tela inteira).
class FoodWinesLoading extends FoodWinesState {}

class FoodWinesLoaded extends FoodWinesState {
  final List<RecommendedWine> items;
  final bool hasMore;

  /// Offset da próxima página (válido quando [hasMore]).
  final int nextOffset;

  /// Total informado pela API.
  final int total;

  /// Carregando a próxima página (indicador no rodapé).
  final bool isLoadingMore;

  /// Chave i18n do erro ao carregar mais (rodapé com "tentar novamente").
  final String? loadMoreError;

  /// Pull-to-refresh em andamento.
  final bool isRefreshing;

  /// Chave i18n do erro no pull-to-refresh (itens atuais preservados).
  final String? refreshError;

  /// Chave i18n de falha ao favoritar (SnackBar). Transitório: não é
  /// copiado por [copyWith].
  final String? favoriteErrorMessage;

  FoodWinesLoaded({
    required this.items,
    required this.hasMore,
    required this.nextOffset,
    required this.total,
    this.isLoadingMore = false,
    this.loadMoreError,
    this.isRefreshing = false,
    this.refreshError,
    this.favoriteErrorMessage,
  });

  FoodWinesLoaded copyWith({
    List<RecommendedWine>? items,
    bool? hasMore,
    int? nextOffset,
    int? total,
    bool? isLoadingMore,
    String? loadMoreError,
    bool clearLoadMoreError = false,
    bool? isRefreshing,
    String? refreshError,
    bool clearRefreshError = false,
    String? favoriteErrorMessage,
  }) {
    return FoodWinesLoaded(
      items: items ?? this.items,
      hasMore: hasMore ?? this.hasMore,
      nextOffset: nextOffset ?? this.nextOffset,
      total: total ?? this.total,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      loadMoreError:
          clearLoadMoreError ? null : (loadMoreError ?? this.loadMoreError),
      isRefreshing: isRefreshing ?? this.isRefreshing,
      refreshError:
          clearRefreshError ? null : (refreshError ?? this.refreshError),
      favoriteErrorMessage: favoriteErrorMessage,
    );
  }
}

/// Nenhum vinho para a categoria.
class FoodWinesEmpty extends FoodWinesState {}

/// Erro ao carregar a primeira página.
class FoodWinesError extends FoodWinesState {
  /// Chave i18n.
  final String message;

  FoodWinesError({required this.message});
}

/// 409 `ONBOARDING_REQUIRED`: a tela mostra CTA para o quiz.
class FoodWinesOnboardingRequired extends FoodWinesState {}

/// 401: logout já executado, a página volta ao login (mesmo fluxo da home).
class FoodWinesSessionExpired extends FoodWinesState {
  /// Chave i18n.
  final String message;

  FoodWinesSessionExpired({required this.message});
}
