import 'package:essentials/essentials.dart';

import '../entity/collection_item.dart';
import '../repository/collections_repository.dart';

class GetCollections implements UnitUseCase<List<CollectionItem>> {
  final CollectionsRepository _repository;

  GetCollections(this._repository);

  @override
  Future<Try<List<CollectionItem>>> call() => _repository.getCollections();
}
