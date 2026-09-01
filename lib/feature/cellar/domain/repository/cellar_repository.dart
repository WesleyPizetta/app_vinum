import 'package:essentials/essentials.dart';

import '../entity/cellar_item.dart';

abstract class CellarRepository {
  Future<Try<List<CellarItem>>> getCellarItems();
}
