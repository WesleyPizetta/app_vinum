import 'package:essentials/essentials.dart';

import '../entity/recommended_wine.dart';
import '../repository/recommendation_repository.dart';

class GetRecommendationsParams {
  final int limit;

  const GetRecommendationsParams({this.limit = 10});
}

class GetRecommendations
    implements UseCase<List<RecommendedWine>, GetRecommendationsParams> {
  final RecommendationRepository _repository;

  GetRecommendations(this._repository);

  @override
  Future<Try<List<RecommendedWine>>> call(GetRecommendationsParams params) =>
      _repository.getRecommendations(limit: params.limit);
}
