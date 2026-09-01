import 'package:essentials/essentials.dart';

import '../entity/cellar_item.dart';
import '../repository/cellar_repository.dart';

class GetCellarItems implements UnitUseCase<List<CellarItem>> {
  final CellarRepository _repository;

  GetCellarItems(this._repository);

  @override
  Future<Try<List<CellarItem>>> call() => _repository.getCellarItems();
}
