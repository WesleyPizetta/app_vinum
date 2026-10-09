import 'package:essentials/essentials.dart';

import '../entity/cellar_reviews_page.dart';
import '../repository/cellar_repository.dart';

class GetMyReviewsParams {
  final int limit;
  final int offset;

  const GetMyReviewsParams({this.limit = 20, this.offset = 0});
}

/// Página das avaliações do usuário ("Minha adega", mais recentes primeiro).
class GetMyReviews implements UseCase<CellarReviewsPage, GetMyReviewsParams> {
  final CellarRepository _repository;

  GetMyReviews(this._repository);

  @override
  Future<Try<CellarReviewsPage>> call(GetMyReviewsParams params) =>
      _repository.getMyReviews(
        limit: params.limit,
        offset: params.offset,
      );
}
