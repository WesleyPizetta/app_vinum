import 'wine_match_reason.dart';

/// Resultado de `GET /v1/me/wines/{wine_id}/match`: afinidade do vinho com
/// o perfil do usuário e os motivos (positivos primeiro).
class WineMatch {
  final String wineId;

  /// Afinidade com o perfil do usuário (0–100).
  final int matchPercent;
  final bool isFavorite;
  final List<WineMatchReason> reasons;

  const WineMatch({
    required this.wineId,
    required this.matchPercent,
    this.isFavorite = false,
    this.reasons = const [],
  });
}
