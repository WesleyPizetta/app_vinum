import 'package:essentials/essentials.dart';

import '../entity/review.dart';
import '../entity/review_tag.dart';
import '../repository/review_repository.dart';

class CreateReviewParams {
  final String wineId;
  final double nota;
  final String? comentario;
  final List<ReviewTag> tags;
  final String token;

  const CreateReviewParams({
    required this.wineId,
    required this.nota,
    this.comentario,
    this.tags = const [],
    required this.token,
  });
}

class CreateReview implements UseCase<Review, CreateReviewParams> {
  final ReviewRepository _repository;

  CreateReview(this._repository);

  @override
  Future<Try<Review>> call(CreateReviewParams params) =>
      _repository.createReview(
        wineId: params.wineId,
        nota: params.nota,
        comentario: params.comentario,
        tags: params.tags,
        token: params.token,
      );
}
