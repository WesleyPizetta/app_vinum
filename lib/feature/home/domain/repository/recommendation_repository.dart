import 'package:essentials/essentials.dart';

import '../entity/food_category.dart';
import '../entity/recommendation_page.dart';
import '../entity/recommended_wine.dart';
import '../entity/search_result.dart';
import '../entity/wine_match.dart';

abstract class RecommendationRepository {
  /// Recomendação geral (home). Falhas conhecidas usam os códigos de
  /// `RecommendationFailureCode`.
  Future<Try<List<RecommendedWine>>> getRecommendations({int? limit});

  /// Página de recomendações, opcionalmente filtrada por [food].
  /// Falhas conhecidas usam os códigos de `RecommendationFailureCode`.
  Future<Try<RecommendationPage>> getRecommendationsPage({
    int? limit,
    int offset = 0,
    FoodCategory? food,
  });

  /// Afinidade de [wineId] com o perfil do usuário e os motivos.
  /// Falhas conhecidas usam os códigos de `RecommendationFailureCode`
  /// (`onboardingRequired` no 409, `notFound` no 404).
  Future<Try<WineMatch>> getWineMatch(String wineId);

  /// Busca por texto, paginada. Falhas conhecidas usam os códigos de
  /// `RecommendationFailureCode` (`badRequest` quando [query] tem menos de
  /// 2 letras, `onboardingRequired` no 409).
  Future<Try<SearchResult>> search({
    required String query,
    int? limit,
    int offset = 0,
  });
}
