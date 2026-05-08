import 'package:essentials/essentials.dart';

import '../entity/review.dart';

abstract class ReviewRepository {
  Future<Try<List<Review>>> getWineReviews(String wineId);

  Future<Try<Review>> createReview({
    required String wineId,
    required String usuarioId,
    required double nota,
    String? comentario,
    String? token,
  });

  Future<Try<Review>> updateReview({
    required String id,
    required double nota,
    String? comentario,
    required String token,
  });

  Future<Try<void>> deleteReview({
    required String id,
    required String token,
  });
}
