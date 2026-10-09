import '../../../../core/utils/json_utils.dart';
import '../../domain/entity/cellar_reviews_page.dart';
import 'cellar_review_model.dart';

/// Corpo paginado de `GET /v1/me/reviews`:
/// `{"reviews": [...], "pagination": {"offset", "limit", "has_more",
/// "next_offset"}}`.
///
/// Mesmas regras defensivas de `FavoriteWinesPageModel`: sem `pagination`
/// (ou página vazia) a página é tratada como a última.
class CellarReviewsPageModel {
  final List<CellarReviewModel> items;
  final int offset;
  final bool hasMore;
  final int? nextOffset;

  const CellarReviewsPageModel({
    required this.items,
    required this.offset,
    required this.hasMore,
    this.nextOffset,
  });

  /// Retorna `null` se o corpo não seguir o contrato (não é objeto ou
  /// `reviews` não é lista). [requestedOffset] é usado quando a resposta
  /// não informa o offset.
  static CellarReviewsPageModel? tryParse(
    dynamic body, {
    int requestedOffset = 0,
  }) {
    final map = JsonUtils.asMap(body);
    if (map == null) return null;
    final rawList = JsonUtils.asList(map['reviews']);
    if (rawList == null) return null;

    final items = rawList
        .map(CellarReviewModel.tryParse)
        .whereType<CellarReviewModel>()
        .toList(growable: false);

    final pagination = JsonUtils.asMap(map['pagination']);
    final parsedOffset = JsonUtils.readInt(pagination?['offset']);
    final offset = parsedOffset != null && parsedOffset >= 0
        ? parsedOffset
        : (requestedOffset < 0 ? 0 : requestedOffset);

    var hasMore = JsonUtils.readBool(pagination?['has_more']) ?? false;
    if (rawList.isEmpty) hasMore = false;

    int? nextOffset;
    if (hasMore) {
      final parsedNext = JsonUtils.readInt(pagination?['next_offset']);
      // O servidor conta os itens brutos (inclusive os descartados aqui).
      nextOffset = parsedNext != null && parsedNext > offset
          ? parsedNext
          : offset + rawList.length;
    }

    return CellarReviewsPageModel(
      items: items,
      offset: offset,
      hasMore: hasMore,
      nextOffset: nextOffset,
    );
  }

  CellarReviewsPage toEntity() => CellarReviewsPage(
        items: items.map((m) => m.toEntity()).toList(growable: false),
        offset: offset,
        hasMore: hasMore,
        nextOffset: nextOffset,
      );
}
