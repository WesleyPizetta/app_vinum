import 'package:essentials/essentials.dart';

import '../entity/wine.dart';

abstract class WineRepository {
  Future<Try<List<Wine>>> getWines();
  Future<Try<Wine>> getWineById(String id);
}
