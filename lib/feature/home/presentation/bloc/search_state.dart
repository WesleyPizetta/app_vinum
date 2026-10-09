import '../../domain/entity/food_category.dart';
import '../../domain/entity/recommended_wine.dart';

sealed class SearchState {}

/// Campo vazio: a tela mostra a dica inicial.
class SearchIdle extends SearchState {}

/// Menos de 2 letras: a tela pede para continuar digitando.
class SearchQueryTooShort extends SearchState {
  final String query;

  SearchQueryTooShort({required this.query});
}

/// Buscando a primeira página de [query].
class SearchLoading extends SearchState {
  final String query;

  SearchLoading({required this.query});
}

class SearchLoaded extends SearchState {
  final String query;

  /// Comidas reconhecidas no texto (chips que abrem a lista por comida).
  final List<FoodCategory> foods;
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

  /// Chave i18n de falha ao favoritar (SnackBar). Transitório: não é
  /// copiado por [copyWith].
  final String? favoriteErrorMessage;

  SearchLoaded({
    required this.query,
    this.foods = const [],
    required this.items,
    required this.hasMore,
    required this.nextOffset,
    required this.total,
    this.isLoadingMore = false,
    this.loadMoreError,
    this.favoriteErrorMessage,
  });

  SearchLoaded copyWith({
    List<RecommendedWine>? items,
    bool? hasMore,
    int? nextOffset,
    int? total,
    bool? isLoadingMore,
    String? loadMoreError,
    bool clearLoadMoreError = false,
    String? favoriteErrorMessage,
  }) {
    return SearchLoaded(
      query: query,
      foods: foods,
      items: items ?? this.items,
      hasMore: hasMore ?? this.hasMore,
      nextOffset: nextOffset ?? this.nextOffset,
      total: total ?? this.total,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      loadMoreError:
          clearLoadMoreError ? null : (loadMoreError ?? this.loadMoreError),
      favoriteErrorMessage: favoriteErrorMessage,
    );
  }
}

/// Nenhum vinho para [query]. [foods] ainda pode trazer comidas
/// reconhecidas (chips).
class SearchEmpty extends SearchState {
  final String query;
  final List<FoodCategory> foods;

  SearchEmpty({required this.query, this.foods = const []});
}

/// Erro ao buscar a primeira página.
class SearchError extends SearchState {
  final String query;

  /// Chave i18n.
  final String message;

  SearchError({required this.query, required this.message});
}

/// 409 `ONBOARDING_REQUIRED`: a tela mostra CTA para o quiz.
class SearchOnboardingRequired extends SearchState {}

/// 401: logout já executado, a página volta ao login.
class SearchSessionExpired extends SearchState {
  /// Chave i18n.
  final String message;

  SearchSessionExpired({required this.message});
}
