import 'package:essentials/essentials.dart';

import '../entity/review.dart';
import '../entity/review_tag.dart';
import '../repository/review_repository.dart';

class UpdateReviewParams {
  final String id;
  final double nota;
  final String? comentario;
  final List<ReviewTag> tags;
  final String token;

  const UpdateReviewParams({
    required this.id,
    required this.nota,
    this.comentario,
    this.tags = const [],
    required this.token,
  });
}

class UpdateReview implements UseCase<Review, UpdateReviewParams> {
  final ReviewRepository _repository;

  UpdateReview(this._repository);

  @override
  Future<Try<Review>> call(UpdateReviewParams params) =>
      _repository.updateReview(
        id: params.id,
        nota: params.nota,
        comentario: params.comentario,
        tags: params.tags,
        token: params.token,
      );
}
