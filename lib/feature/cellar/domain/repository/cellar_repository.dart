import 'package:essentials/essentials.dart';

import '../entity/cellar_reviews_page.dart';

/// "Minha adega": as avaliações do usuário autenticado.
///
/// Falhas conhecidas usam os códigos de `CellarFailureCode`.
abstract class CellarRepository {
  /// `GET /v1/me/reviews?limit=&offset=` (mais recentes primeiro).
  Future<Try<CellarReviewsPage>> getMyReviews({
    int limit = 20,
    int offset = 0,
  });
}
