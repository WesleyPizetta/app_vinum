import 'package:essentials/essentials.dart';

import '../entity/review.dart';
import '../entity/review_tag.dart';

abstract class ReviewRepository {
  Future<Try<List<ReviewTagOption>>> getTags();

  Future<Try<List<Review>>> getWineReviews(String wineId);

  Future<Try<Review>> createReview({
    required String wineId,
    required double nota,
    String? comentario,
    required List<ReviewTag> tags,
    required String token,
  });

  Future<Try<Review>> updateReview({
    required String id,
    required double nota,
    String? comentario,
    required List<ReviewTag> tags,
    required String token,
  });

  Future<Try<void>> deleteReview({
    required String id,
    required String token,
  });
}
