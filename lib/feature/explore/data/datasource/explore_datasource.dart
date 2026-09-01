import '../model/explore_item_model.dart';

abstract class ExploreDatasource {
  Future<List<ExploreItemModel>> getExploreItems();
}
