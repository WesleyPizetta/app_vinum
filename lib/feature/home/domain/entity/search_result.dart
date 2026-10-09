import 'food_category.dart';
import 'recommendation_page.dart';

/// Uma página de `GET /v1/me/search`.
///
/// [foods] são as categorias de comida reconhecidas no texto (ex.: "picanha"
/// -> `meat`); [page] traz os vinhos (mesmo formato das recomendações) com a
/// paginação.
class SearchResult {
  final String query;
  final List<FoodCategory> foods;
  final RecommendationPage page;

  const SearchResult({
    required this.query,
    this.foods = const [],
    required this.page,
  });
}
