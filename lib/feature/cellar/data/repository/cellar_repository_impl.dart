import 'package:essentials/essentials.dart';

import '../../domain/entity/cellar_item.dart';
import '../../domain/repository/cellar_repository.dart';
import '../datasource/cellar_datasource.dart';

class CellarRepositoryImpl implements CellarRepository {
  final CellarDatasource _datasource;

  const CellarRepositoryImpl(this._datasource);

  @override
  Future<Try<List<CellarItem>>> getCellarItems() async {
    try {
      final models = await _datasource.getCellarItems();
      return Try.success(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Try.reject(UnknownFailure(e));
    }
  }
}
