import 'package:essentials/essentials.dart';

import '../entity/food_category.dart';
import '../entity/recommendation_page.dart';
import '../repository/recommendation_repository.dart';

class GetFoodRecommendationsParams {
  final FoodCategory food;
  final int limit;
  final int offset;

  const GetFoodRecommendationsParams({
    required this.food,
    this.limit = 20,
    this.offset = 0,
  });
}

/// Vinhos recomendados para uma categoria de comida, paginados.
class GetFoodRecommendations
    implements UseCase<RecommendationPage, GetFoodRecommendationsParams> {
  final RecommendationRepository _repository;

  GetFoodRecommendations(this._repository);

  @override
  Future<Try<RecommendationPage>> call(GetFoodRecommendationsParams params) =>
      _repository.getRecommendationsPage(
        limit: params.limit,
        offset: params.offset,
        food: params.food,
      );
}
