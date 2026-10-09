sealed class WineMatchEvent {}

/// Carrega a afinidade/motivos do vinho. Também serve de "tentar novamente".
class WineMatchStarted extends WineMatchEvent {
  final String wineId;

  WineMatchStarted({required this.wineId});
}
