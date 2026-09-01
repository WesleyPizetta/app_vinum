sealed class HomeEvent {}

class HomeStarted extends HomeEvent {}

class HomeRecommendationFavoriteToggled extends HomeEvent {
  final String wineId;

  HomeRecommendationFavoriteToggled({required this.wineId});
}

class HomeHighlightFavoriteToggled extends HomeEvent {
  final String wineId;

  HomeHighlightFavoriteToggled({required this.wineId});
}
