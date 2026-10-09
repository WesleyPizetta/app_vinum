import 'recommended_wine.dart';

/// Uma página de `GET /v1/me/recommendations` (lista + `pagination`).
class RecommendationPage {
  final List<RecommendedWine> items;

  /// Offset usado nesta página.
  final int offset;

  /// Total de vinhos disponíveis para a consulta.
  final int total;

  /// Se há mais páginas depois desta.
  final bool hasMore;

  /// Offset da próxima página; `null` quando [hasMore] é `false`.
  final int? nextOffset;

  const RecommendationPage({
    required this.items,
    this.offset = 0,
    required this.total,
    required this.hasMore,
    this.nextOffset,
  });
}
