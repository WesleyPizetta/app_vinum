import 'package:essentials/essentials.dart';

import '../entity/sample_entity.dart';

abstract class SampleRepository {
  Future<Try<List<SampleEntity>>> getItems();
  Future<Try<SampleEntity>> getItemById(String id);
}
