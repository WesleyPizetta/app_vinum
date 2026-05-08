import '../model/review_model.dart';

abstract class ReviewDatasource {
  Future<List<ReviewModel>> getWineReviews(String wineId);

  Future<ReviewModel> createReview({
    required String wineId,
    required String usuarioId,
    required double nota,
    String? comentario,
    String? token,
  });

  Future<ReviewModel> updateReview({
    required String id,
    required double nota,
    String? comentario,
    required String token,
  });

  Future<void> deleteReview({required String id, required String token});
}
