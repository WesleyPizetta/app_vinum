sealed class HomeEvent {}

class HomeStarted extends HomeEvent {
  /// Relê o usuário em cache (ex.: apelido alterado no perfil) mesmo com a
  /// home já carregada, para atualizar a saudação.
  final bool refreshUser;

  HomeStarted({this.refreshUser = false});
}

class HomeRecommendationFavoriteToggled extends HomeEvent {
  final String wineId;

  HomeRecommendationFavoriteToggled({required this.wineId});
}

class HomeHighlightFavoriteToggled extends HomeEvent {
  final String wineId;

  HomeHighlightFavoriteToggled({required this.wineId});
}
