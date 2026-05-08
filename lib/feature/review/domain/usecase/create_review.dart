import 'package:essentials/essentials.dart';

import '../entity/review.dart';
import '../repository/review_repository.dart';

class CreateReviewParams {
  final String wineId;
  final String usuarioId;
  final double nota;
  final String? comentario;
  final String? token;

  const CreateReviewParams({
    required this.wineId,
    required this.usuarioId,
    required this.nota,
    this.comentario,
    this.token,
  });
}

class CreateReview implements UseCase<Review, CreateReviewParams> {
  final ReviewRepository _repository;

  CreateReview(this._repository);

  @override
  Future<Try<Review>> call(CreateReviewParams params) =>
      _repository.createReview(
        wineId: params.wineId,
        usuarioId: params.usuarioId,
        nota: params.nota,
        comentario: params.comentario,
        token: params.token,
      );
}
