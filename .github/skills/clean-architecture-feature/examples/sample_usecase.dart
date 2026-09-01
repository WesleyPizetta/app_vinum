import 'package:essentials/essentials.dart';

import '../entity/sample_entity.dart';
import '../repository/sample_repository.dart';

class GetSampleItems implements UnitUseCase<List<SampleEntity>> {
  final SampleRepository _repository;

  GetSampleItems(this._repository);

  @override
  Future<Try<List<SampleEntity>>> call() => _repository.getItems();
}
