import 'package:essentials/essentials.dart';

import '../entity/collection_item.dart';

abstract class CollectionsRepository {
  Future<Try<List<CollectionItem>>> getCollections();
}
