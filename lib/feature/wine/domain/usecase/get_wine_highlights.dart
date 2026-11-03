import 'package:essentials/essentials.dart';

import '../entity/wine_highlights.dart';
import '../repository/wine_repository.dart';

class GetWineHighlightsParams {
  final int limit;

  const GetWineHighlightsParams({this.limit = 10});
}

/// Destaques da semana (endpoint público).
class GetWineHighlights
    implements UseCase<WineHighlights, GetWineHighlightsParams> {
  final WineRepository _repository;

  GetWineHighlights(this._repository);

  @override
  Future<Try<WineHighlights>> call(GetWineHighlightsParams params) =>
      _repository.getHighlights(limit: params.limit);
}
