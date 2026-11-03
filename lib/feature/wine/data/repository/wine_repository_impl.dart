import 'package:essentials/essentials.dart';

import '../../domain/entity/wine.dart';
import '../../domain/entity/wine_highlights.dart';
import '../../domain/entity/wine_failure_code.dart';
import '../../domain/repository/wine_repository.dart';
import '../datasource/wine_datasource.dart';
import '../datasource/wine_remote_datasource.dart';

class WineRepositoryImpl implements WineRepository {
  final WineDatasource _datasource;

  WineRepositoryImpl(this._datasource);

  @override
  Future<Try<List<Wine>>> getWines() async {
    try {
      final models = await _datasource.getWines();
      final wines = models.map((m) => m.toEntity()).toList();
      return Try.success(wines);
    } on WineApiException catch (e) {
      return Try.reject(_toFailure(e));
    } catch (e) {
      return Try.reject(UnknownFailure(e));
    }
  }

  @override
  Future<Try<Wine>> getWineById(String id) async {
    try {
      final model = await _datasource.getWineById(id);
      return Try.success(model.toEntity());
    } on WineApiException catch (e) {
      return Try.reject(_toFailure(e));
    } catch (e) {
      return Try.reject(UnknownFailure(e));
    }
  }

  @override
  Future<Try<WineHighlights>> getHighlights({int limit = 10}) async {
    try {
      final model = await _datasource.getHighlights(limit: limit);
      return Try.success(model.toEntity());
    } on WineApiException catch (e) {
      return Try.reject(_toFailure(e));
    } catch (e) {
      return Try.reject(UnknownFailure(e));
    }
  }

  KnownFailure _toFailure(WineApiException e) {
    final code = switch (e.statusCode) {
      0 => WineFailureCode.invalidResponse,
      404 => WineFailureCode.notFound,
      >= 500 => WineFailureCode.server,
      _ => WineFailureCode.requestFailed,
    };
    return KnownFailure(code, e, message: e.message);
  }
}
