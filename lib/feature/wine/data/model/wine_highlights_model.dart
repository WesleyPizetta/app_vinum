import '../../../../core/utils/json_utils.dart';
import '../../domain/entity/wine_highlights.dart';
import 'wine_model.dart';

/// Corpo de `GET /v1/wines/highlights`: `{"week": "2026-W40", "wines": [...]}`.
class WineHighlightsModel {
  final String week;
  final List<WineModel> wines;

  const WineHighlightsModel({this.week = '', this.wines = const []});

  /// Retorna `null` se o corpo não for objeto ou `wines` não for lista.
  /// Vinhos inválidos e repetidos (mesmo id) são descartados.
  static WineHighlightsModel? tryParse(dynamic raw) {
    final map = JsonUtils.asMap(raw);
    if (map == null) return null;
    final list = JsonUtils.asList(map['wines']);
    if (list == null) return null;

    final seen = <String>{};
    final wines = list
        .map(WineModel.tryParse)
        .whereType<WineModel>()
        .where((wine) => seen.add(wine.id))
        .toList(growable: false);

    return WineHighlightsModel(
      week: JsonUtils.readString(map['week']) ?? '',
      wines: wines,
    );
  }

  WineHighlights toEntity() => WineHighlights(
        week: week,
        wines: wines.map((w) => w.toEntity()).toList(growable: false),
      );
}
