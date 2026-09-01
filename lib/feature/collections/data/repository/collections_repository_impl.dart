import 'package:essentials/essentials.dart';

import '../../domain/entity/collection_item.dart';
import '../../domain/repository/collections_repository.dart';
import '../datasource/collections_datasource.dart';

class CollectionsRepositoryImpl implements CollectionsRepository {
  final CollectionsDatasource _datasource;

  const CollectionsRepositoryImpl(this._datasource);

  @override
  Future<Try<List<CollectionItem>>> getCollections() async {
    try {
      final models = await _datasource.getCollections();
      return Try.success(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Try.reject(UnknownFailure(e));
    }
  }
}
