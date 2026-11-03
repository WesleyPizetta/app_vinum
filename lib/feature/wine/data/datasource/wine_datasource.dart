import '../model/wine_highlights_model.dart';
import '../model/wine_model.dart';

abstract class WineDatasource {
  Future<List<WineModel>> getWines();
  Future<WineModel> getWineById(String id);

  /// Destaques da semana (`GET /v1/wines/highlights`).
  Future<WineHighlightsModel> getHighlights({int limit = 10});
}
