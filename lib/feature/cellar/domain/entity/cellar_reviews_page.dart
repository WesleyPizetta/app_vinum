import 'cellar_review.dart';

/// Uma página de `GET /v1/me/reviews` (mais recentes primeiro).
class CellarReviewsPage {
  final List<CellarReview> items;

  /// Offset usado nesta página.
  final int offset;

  /// Se há mais páginas depois desta.
  final bool hasMore;

  /// Offset da próxima página; `null` quando [hasMore] é `false`.
  final int? nextOffset;

  const CellarReviewsPage({
    required this.items,
    this.offset = 0,
    required this.hasMore,
    this.nextOffset,
  });
}
