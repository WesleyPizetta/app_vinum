import 'package:essentials/essentials.dart';

import '../entity/review.dart';
import '../repository/review_repository.dart';

class GetWineReviews implements UseCase<List<Review>, String> {
  final ReviewRepository _repository;

  GetWineReviews(this._repository);

  @override
  Future<Try<List<Review>>> call(String wineId) =>
      _repository.getWineReviews(wineId);
}
