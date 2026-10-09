import 'package:essentials/essentials.dart';

import '../entity/search_result.dart';
import '../repository/recommendation_repository.dart';

class SearchWinesParams {
  final String query;
  final int limit;
  final int offset;

  const SearchWinesParams({
    required this.query,
    this.limit = 20,
    this.offset = 0,
  });
}

/// Busca por texto (vinhos e pratos), paginada e ordenada pelo gosto do
/// usuário.
class SearchWines implements UseCase<SearchResult, SearchWinesParams> {
  final RecommendationRepository _repository;

  SearchWines(this._repository);

  @override
  Future<Try<SearchResult>> call(SearchWinesParams params) =>
      _repository.search(
        query: params.query,
        limit: params.limit,
        offset: params.offset,
      );
}
