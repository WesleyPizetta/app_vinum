import 'package:essentials/essentials.dart';

import '../entity/wine.dart';
import '../repository/wine_repository.dart';

class GetWines implements UnitUseCase<List<Wine>> {
  final WineRepository _repository;

  GetWines(this._repository);

  @override
  Future<Try<List<Wine>>> call() => _repository.getWines();
}
