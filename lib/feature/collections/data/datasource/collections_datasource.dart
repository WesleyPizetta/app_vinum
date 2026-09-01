import '../model/collection_item_model.dart';

abstract class CollectionsDatasource {
  Future<List<CollectionItemModel>> getCollections();
}
