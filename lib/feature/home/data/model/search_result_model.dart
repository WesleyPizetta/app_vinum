import '../../../../core/utils/json_utils.dart';
import '../../domain/entity/food_category.dart';
import '../../domain/entity/search_result.dart';
import 'recommendation_page_model.dart';

/// Corpo de `GET /v1/me/search`:
/// `{"query": "...", "foods": [{"key": "meat"}], "wines": [...],
/// "pagination": {...}}`. Os itens de `wines` têm o mesmo formato das
/// recomendações e a paginação segue as mesmas regras defensivas.
class SearchResultModel {
  final String query;
  final List<FoodCategory> foods;
  final RecommendationPageModel page;

  const SearchResultModel({
    required this.query,
    required this.foods,
    required this.page,
  });

  /// Retorna `null` se o corpo não for objeto ou `wines` não for lista.
  /// Comidas desconhecidas ou repetidas são descartadas. [requestedQuery] é
  /// usado quando a resposta não traz `query`.
  static SearchResultModel? tryParse(
    dynamic body, {
    String requestedQuery = '',
    int requestedOffset = 0,
  }) {
    final map = JsonUtils.asMap(body);
    if (map == null) return null;

    final page = RecommendationPageModel.tryParse(
      map,
      requestedOffset: requestedOffset,
      listKey: 'wines',
    );
    if (page == null) return null;

    final foods = <FoodCategory>[];
    for (final raw in JsonUtils.asList(map['foods']) ?? const []) {
      // Aceita `{"key": "meat"}` e, defensivamente, `"meat"`.
      final item = JsonUtils.asMap(raw);
      final key = item != null
          ? JsonUtils.readString(item['key'])
          : JsonUtils.readString(raw);
      final food = FoodCategory.fromApiValue(key);
      if (food != null && !foods.contains(food)) foods.add(food);
    }

    return SearchResultModel(
      query: JsonUtils.readString(map['query']) ?? requestedQuery,
      foods: List.unmodifiable(foods),
      page: page,
    );
  }

  SearchResult toEntity() => SearchResult(
        query: query,
        foods: foods,
        page: page.toEntity(),
      );
}
