import '../model/review_model.dart';
import '../../domain/entity/review_tag.dart';

abstract class ReviewDatasource {
  Future<List<ReviewTagOption>> getTags();

  Future<List<ReviewModel>> getWineReviews(String wineId);

  Future<ReviewModel> createReview({
    required String wineId,
    required double nota,
    String? comentario,
    required List<ReviewTag> tags,
    required String token,
  });

  Future<ReviewModel> updateReview({
    required String id,
    required double nota,
    String? comentario,
    required List<ReviewTag> tags,
    required String token,
  });

  Future<void> deleteReview({required String id, required String token});
}
