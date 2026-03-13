import 'package:essentials/essentials.dart';

import '../entity/wine.dart';
import '../repository/wine_repository.dart';

class GetWineById implements UseCase<Wine, String> {
  final WineRepository _repository;

  GetWineById(this._repository);

  @override
  Future<Try<Wine>> call(String id) => _repository.getWineById(id);
}
