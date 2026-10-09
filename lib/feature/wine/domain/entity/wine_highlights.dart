import 'wine.dart';

/// Destaques da semana (`GET /v1/wines/highlights`).
class WineHighlights {
  /// Semana ISO dos destaques (ex.: "2026-W40"); vazio quando não informada.
  final String week;
  final List<Wine> wines;

  const WineHighlights({this.week = '', this.wines = const []});
}
