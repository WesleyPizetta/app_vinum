import '../../../../core/utils/json_utils.dart';
import '../../domain/entity/favorite_wines_page.dart';
import 'favorite_wine_model.dart';

/// Corpo paginado de `GET /v1/me/favorites`:
/// `{"favorites": [...], "pagination": {"offset", "limit", "total",
/// "has_more", "next_offset"}}`.
///
/// Mesmas regras defensivas de `RecommendationPageModel`: sem `pagination`
/// (ou página vazia) a página é tratada como a última.
class FavoriteWinesPageModel {
  final List<FavoriteWineModel> items;
  final int offset;
  final int total;
  final bool hasMore;
  final int? nextOffset;

  const FavoriteWinesPageModel({
    required this.items,
    required this.offset,
    required this.total,
    required this.hasMore,
    this.nextOffset,
  });

  /// Retorna `null` se o corpo não seguir o contrato (não é objeto ou
  /// `favorites` não é lista). [requestedOffset] é usado quando a resposta
  /// não informa o offset.
  static FavoriteWinesPageModel? tryParse(
    dynamic body, {
    int requestedOffset = 0,
  }) {
    final map = JsonUtils.asMap(body);
    if (map == null) return null;
    final rawList = JsonUtils.asList(map['favorites']);
    if (rawList == null) return null;

    final items = rawList
        .map(FavoriteWineModel.tryParse)
        .whereType<FavoriteWineModel>()
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

    final parsedTotal = JsonUtils.readInt(pagination?['total']);
    final minimumTotal = offset + rawList.length;
    final total = parsedTotal != null && parsedTotal >= minimumTotal
        ? parsedTotal
        : minimumTotal;

    return FavoriteWinesPageModel(
      items: items,
      offset: offset,
      total: total,
      hasMore: hasMore,
      nextOffset: nextOffset,
    );
  }

  FavoriteWinesPage toEntity() => FavoriteWinesPage(
        items: items.map((m) => m.toEntity()).toList(growable: false),
        offset: offset,
        total: total,
        hasMore: hasMore,
        nextOffset: nextOffset,
      );
}
