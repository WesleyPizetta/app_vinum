import '../model/wine_model.dart';

abstract class WineDatasource {
  Future<List<WineModel>> getWines();
  Future<WineModel> getWineById(String id);
}
