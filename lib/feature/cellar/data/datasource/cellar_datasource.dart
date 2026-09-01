import '../model/cellar_item_model.dart';

abstract class CellarDatasource {
  Future<List<CellarItemModel>> getCellarItems();
}
