import '../../../../core/utils/json_utils.dart';
import '../../domain/entity/wine_match.dart';
import 'wine_match_reason_model.dart';

/// Corpo de `GET /v1/me/wines/{wine_id}/match`:
/// `{"wine_id", "match_percent", "is_favorite", "reasons": [...],
/// "effective_profile": {...}}`. `effective_profile` não é usado pelo app.
class WineMatchModel {
  final String wineId;
  final int matchPercent;
  final bool isFavorite;
  final List<WineMatchReasonModel> reasons;

  const WineMatchModel({
    required this.wineId,
    required this.matchPercent,
    this.isFavorite = false,
    this.reasons = const [],
  });

  /// Retorna `null` se o corpo não for objeto ou faltar `match_percent`.
  /// [requestedWineId] é usado quando a resposta não traz `wine_id`.
  static WineMatchModel? tryParse(dynamic body, {String? requestedWineId}) {
    final map = JsonUtils.asMap(body);
    if (map == null) return null;

    final match = JsonUtils.readDouble(map['match_percent']);
    if (match == null || !match.isFinite) return null;

    final rawId = map['wine_id'];
    final wineId = JsonUtils.readInt(rawId)?.toString() ??
        JsonUtils.readString(rawId) ??
        requestedWineId;
    if (wineId == null) return null;

    return WineMatchModel(
      wineId: wineId,
      matchPercent: match.round().clamp(0, 100).toInt(),
      isFavorite: JsonUtils.readBool(map['is_favorite']) ?? false,
      reasons: WineMatchReasonModel.tryParseList(map['reasons']),
    );
  }

  WineMatch toEntity() => WineMatch(
        wineId: wineId,
        matchPercent: matchPercent,
        isFavorite: isFavorite,
        reasons: reasons.map((r) => r.toEntity()).toList(growable: false),
      );
}
