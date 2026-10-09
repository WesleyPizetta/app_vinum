import 'package:essentials/essentials.dart';

import '../entity/wine_match.dart';
import '../repository/recommendation_repository.dart';

/// "Por que este vinho combina com você?": afinidade + motivos de um vinho.
/// O parâmetro é o id do vinho.
class GetWineMatch implements UseCase<WineMatch, String> {
  final RecommendationRepository _repository;

  GetWineMatch(this._repository);

  @override
  Future<Try<WineMatch>> call(String wineId) =>
      _repository.getWineMatch(wineId);
}
