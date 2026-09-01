import 'package:essentials/essentials.dart';

import '../entity/explore_item.dart';

abstract class ExploreRepository {
  Future<Try<List<ExploreItem>>> getExploreItems();
}
