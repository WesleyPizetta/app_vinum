import '../../../../core/utils/json_utils.dart';
import '../../domain/entity/recommendation_page.dart';
import 'recommended_wine_model.dart';

/// Corpo paginado de `GET /v1/me/recommendations`:
/// `{"recommendations": [...], "pagination": {"offset", "limit", "total",
/// "has_more", "next_offset"}}`.
///
/// O parse de `pagination` é defensivo: se ela faltar ou vier inválida, a
/// página é tratada como a última (`hasMore = false`).
class RecommendationPageModel {
  final List<RecommendedWineModel> items;
  final int offset;
  final int total;
  final bool hasMore;
  final int? nextOffset;

  const RecommendationPageModel({
    required this.items,
    required this.offset,
    required this.total,
    required this.hasMore,
    this.nextOffset,
  });

  /// Retorna `null` se o corpo não seguir o contrato (não é objeto ou
  /// [listKey] não é lista). [requestedOffset] é usado quando a resposta não
  /// informa o offset. [listKey] permite reaproveitar o parse em respostas
  /// com o mesmo formato de item (ex.: `wines` de `GET /v1/me/search`).
  static RecommendationPageModel? tryParse(
    dynamic body, {
    int requestedOffset = 0,
    String listKey = 'recommendations',
  }) {
    final map = JsonUtils.asMap(body);
    if (map == null) return null;
    final rawList = JsonUtils.asList(map[listKey]);
    if (rawList == null) return null;

    final items = rawList
        .map(RecommendedWineModel.tryParse)
        .whereType<RecommendedWineModel>()
        .toList(growable: false);

    final pagination = JsonUtils.asMap(map['pagination']);
    final parsedOffset = JsonUtils.readInt(pagination?['offset']);
    final offset = parsedOffset != null && parsedOffset >= 0
        ? parsedOffset
        : (requestedOffset < 0 ? 0 : requestedOffset);

    // Sem `pagination` (ou `has_more` inválido) -> última página.
    // Página vazia também encerra, para nunca entrar em loop.
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

    return RecommendationPageModel(
      items: items,
      offset: offset,
      total: total,
      hasMore: hasMore,
      nextOffset: nextOffset,
    );
  }

  RecommendationPage toEntity() => RecommendationPage(
        items: items.map((m) => m.toEntity()).toList(growable: false),
        offset: offset,
        total: total,
        hasMore: hasMore,
        nextOffset: nextOffset,
      );
}
