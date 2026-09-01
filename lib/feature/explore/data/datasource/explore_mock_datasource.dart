import '../model/explore_item_model.dart';
import 'explore_datasource.dart';

class ExploreMockDatasource implements ExploreDatasource {
  @override
  Future<List<ExploreItemModel>> getExploreItems() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return const [
      ExploreItemModel(
        id: '1',
        name: 'Château Margaux',
        winery: 'Château Margaux',
        vintage: 2015,
        rating: 4.9,
      ),
      ExploreItemModel(
        id: '2',
        name: 'Barolo Monfortino',
        winery: 'Giacomo Conterno',
        vintage: 2013,
        rating: 4.8,
      ),
      ExploreItemModel(
        id: '3',
        name: 'Almaviva',
        winery: 'Viña Almaviva',
        vintage: 2018,
        rating: 4.7,
      ),
    ];
  }
}
