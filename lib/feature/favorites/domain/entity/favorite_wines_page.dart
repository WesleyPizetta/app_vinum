import 'favorite_wine.dart';

/// Uma página de `GET /v1/me/favorites` (mais recentes primeiro).
class FavoriteWinesPage {
  final List<FavoriteWine> items;

  /// Offset usado nesta página.
  final int offset;

  /// Total de favoritos do usuário.
  final int total;

  /// Se há mais páginas depois desta.
  final bool hasMore;

  /// Offset da próxima página; `null` quando [hasMore] é `false`.
  final int? nextOffset;

  const FavoriteWinesPage({
    required this.items,
    this.offset = 0,
    required this.total,
    required this.hasMore,
    this.nextOffset,
  });
}
