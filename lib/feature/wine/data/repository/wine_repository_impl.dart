import 'package:essentials/essentials.dart';

import '../../domain/entity/wine.dart';
import '../../domain/repository/wine_repository.dart';
import '../datasource/wine_datasource.dart';

class WineRepositoryImpl implements WineRepository {
  final WineDatasource _datasource;

  WineRepositoryImpl(this._datasource);

  @override
  Future<Try<List<Wine>>> getWines() async {
    try {
      final models = await _datasource.getWines();
      final wines = models.map((m) => m.toEntity()).toList();
      return Try.success(wines);
    } catch (e) {
      return Try.reject(UnknownFailure(e));
    }
  }

  @override
  Future<Try<Wine>> getWineById(String id) async {
    try {
      final model = await _datasource.getWineById(id);
      return Try.success(model.toEntity());
    } catch (e) {
      return Try.reject(UnknownFailure(e));
    }
  }
}
