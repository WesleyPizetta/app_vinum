import 'package:essentials/essentials.dart';

import '../../domain/entity/explore_item.dart';
import '../../domain/repository/explore_repository.dart';
import '../datasource/explore_datasource.dart';

class ExploreRepositoryImpl implements ExploreRepository {
  final ExploreDatasource _datasource;

  const ExploreRepositoryImpl(this._datasource);

  @override
  Future<Try<List<ExploreItem>>> getExploreItems() async {
    try {
      final models = await _datasource.getExploreItems();
      return Try.success(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Try.reject(UnknownFailure(e));
    }
  }
}
