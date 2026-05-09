import 'package:essentials/essentials.dart';

import '../../domain/entity/review.dart';
import '../../domain/entity/review_tag.dart';
import '../../domain/repository/review_repository.dart';
import '../datasource/review_datasource.dart';

class ReviewRepositoryImpl implements ReviewRepository {
  final ReviewDatasource _datasource;

  const ReviewRepositoryImpl(this._datasource);

  @override
  Future<Try<List<ReviewTagOption>>> getTags() async {
    try {
      final tags = await _datasource.getTags();
      return Try.success(tags);
    } catch (e) {
      return Try.reject(UnknownFailure(e));
    }
  }

  @override
  Future<Try<List<Review>>> getWineReviews(String wineId) async {
    try {
      final models = await _datasource.getWineReviews(wineId);
      return Try.success(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Try.reject(UnknownFailure(e));
    }
  }

  @override
  Future<Try<Review>> createReview({
    required String wineId,
    required double nota,
    String? comentario,
    required List<ReviewTag> tags,
    required String token,
  }) async {
    try {
      final model = await _datasource.createReview(
        wineId: wineId,
        nota: nota,
        comentario: comentario,
        tags: tags,
        token: token,
      );
      return Try.success(model.toEntity());
    } catch (e) {
      return Try.reject(UnknownFailure(e));
    }
  }

  @override
  Future<Try<Review>> updateReview({
    required String id,
    required double nota,
    String? comentario,
    required List<ReviewTag> tags,
    required String token,
  }) async {
    try {
      final model = await _datasource.updateReview(
        id: id,
        nota: nota,
        comentario: comentario,
        tags: tags,
        token: token,
      );
      return Try.success(model.toEntity());
    } catch (e) {
      return Try.reject(UnknownFailure(e));
    }
  }

  @override
  Future<Try<void>> deleteReview({
    required String id,
    required String token,
  }) async {
    try {
      await _datasource.deleteReview(id: id, token: token);
      return Try.success(null);
    } catch (e) {
      return Try.reject(UnknownFailure(e));
    }
  }
}
