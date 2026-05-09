sealed class ReviewListEvent {}

class ReviewListStarted extends ReviewListEvent {
  final String wineId;
  ReviewListStarted({required this.wineId});
}
