sealed class WineDetailEvent {}

class WineDetailStarted extends WineDetailEvent {
  final String wineId;
  WineDetailStarted({required this.wineId});
}
