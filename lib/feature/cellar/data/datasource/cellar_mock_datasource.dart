import '../model/cellar_item_model.dart';
import 'cellar_datasource.dart';

class CellarMockDatasource implements CellarDatasource {
  @override
  Future<List<CellarItemModel>> getCellarItems() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return const [];
  }
}
