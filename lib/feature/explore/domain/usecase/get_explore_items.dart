import 'package:essentials/essentials.dart';

import '../entity/explore_item.dart';
import '../repository/explore_repository.dart';

class GetExploreItems implements UnitUseCase<List<ExploreItem>> {
  final ExploreRepository _repository;

  GetExploreItems(this._repository);

  @override
  Future<Try<List<ExploreItem>>> call() => _repository.getExploreItems();
}
