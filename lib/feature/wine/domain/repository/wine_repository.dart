import 'package:essentials/essentials.dart';

import '../entity/wine.dart';
import '../entity/wine_highlights.dart';

abstract class WineRepository {
  Future<Try<List<Wine>>> getWines();
  Future<Try<Wine>> getWineById(String id);

  /// Destaques da semana. Falhas conhecidas usam os códigos de
  /// `WineFailureCode`.
  Future<Try<WineHighlights>> getHighlights({int limit = 10});
}
