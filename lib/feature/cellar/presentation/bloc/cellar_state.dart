import '../../domain/entity/cellar_review.dart';

sealed class CellarState {}

class CellarInitial extends CellarState {}

/// Carregando a primeira página (tela inteira).
class CellarLoading extends CellarState {}

class CellarLoaded extends CellarState {
  final List<CellarReview> items;
  final bool hasMore;

  /// Offset da próxima página (válido quando [hasMore]).
  final int nextOffset;

  /// Carregando a próxima página (indicador no rodapé).
  final bool isLoadingMore;

  /// Chave i18n do erro ao carregar mais (rodapé com "tentar novamente").
  final String? loadMoreError;

  /// Refresh em andamento.
  final bool isRefreshing;

  /// Chave i18n do erro no refresh (itens atuais preservados; SnackBar).
  /// Transitório: não é copiado por [copyWith].
  final String? refreshError;

  /// Média das notas carregadas (0–10); `null` sem itens.
  final double? averageRating;

  CellarLoaded({
    required this.items,
    required this.hasMore,
    required this.nextOffset,
    this.isLoadingMore = false,
    this.loadMoreError,
    this.isRefreshing = false,
    this.refreshError,
  }) : averageRating = _average(items);

  static double? _average(List<CellarReview> items) {
    if (items.isEmpty) return null;
    final sum = items.fold<double>(0, (total, r) => total + r.rating);
    return sum / items.length;
  }

  CellarLoaded copyWith({
    List<CellarReview>? items,
    bool? hasMore,
    int? nextOffset,
    bool? isLoadingMore,
    String? loadMoreError,
    bool clearLoadMoreError = false,
    bool? isRefreshing,
    String? refreshError,
  }) {
    return CellarLoaded(
      items: items ?? this.items,
      hasMore: hasMore ?? this.hasMore,
      nextOffset: nextOffset ?? this.nextOffset,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      loadMoreError:
          clearLoadMoreError ? null : (loadMoreError ?? this.loadMoreError),
      isRefreshing: isRefreshing ?? this.isRefreshing,
      refreshError: refreshError,
    );
  }
}

/// O usuário ainda não avaliou nenhum vinho.
class CellarEmpty extends CellarState {}

/// Erro ao carregar a primeira página.
class CellarError extends CellarState {
  /// Chave i18n.
  final String message;

  CellarError({required this.message});
}

/// 401: logout já executado, a tela volta ao login.
class CellarSessionExpired extends CellarState {
  /// Chave i18n.
  final String message;

  CellarSessionExpired({required this.message});
}
