/// Estado (imutável) do cache de favoritos do usuário.
///
/// - [ids]: vinhos favoritos conhecidos (inclui alterações otimistas).
/// - [isLoaded]: se a lista completa já veio de `GET /v1/me/favorites/ids`.
///   Antes disso, só se sabe o estado dos vinhos alterados localmente.
/// - [removed]: vinhos desfavoritados localmente antes de [isLoaded] (depois
///   de carregado, qualquer id fora de [ids] não é favorito).
class FavoriteIds {
  final Set<String> ids;
  final Set<String> removed;
  final bool isLoaded;

  const FavoriteIds({
    this.ids = const {},
    this.removed = const {},
    this.isLoaded = false,
  });

  static const FavoriteIds empty = FavoriteIds();

  /// `true`/`false` quando o estado de [wineId] é conhecido; `null` quando a
  /// lista ainda não foi carregada e o vinho não foi alterado localmente
  /// (nesse caso vale o `is_favorite` que veio da API, se houver).
  bool? isFavorite(String wineId) {
    if (ids.contains(wineId)) return true;
    if (isLoaded || removed.contains(wineId)) return false;
    return null;
  }
}
