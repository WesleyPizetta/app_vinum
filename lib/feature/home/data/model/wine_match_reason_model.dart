import '../../../../core/utils/json_utils.dart';
import '../../domain/entity/wine_match_reason.dart';

/// Item de `reasons`: `{"code": "...", "value": "opcional", "positive": bool}`.
class WineMatchReasonModel {
  final String code;
  final String? value;
  final bool positive;

  const WineMatchReasonModel({
    required this.code,
    this.value,
    this.positive = true,
  });

  /// Retorna `null` se não for objeto ou faltar `code`. O código é
  /// normalizado (trim + minúsculas); códigos desconhecidos são mantidos e
  /// ignorados pela apresentação. Sem `positive` -> `true`.
  static WineMatchReasonModel? tryParse(dynamic json) {
    final map = JsonUtils.asMap(json);
    if (map == null) return null;
    final code = JsonUtils.readString(map['code'])?.toLowerCase();
    if (code == null) return null;
    return WineMatchReasonModel(
      code: code,
      value: JsonUtils.readString(map['value']),
      positive: JsonUtils.readBool(map['positive']) ?? true,
    );
  }

  /// Lista de motivos; itens inválidos são descartados e qualquer valor que
  /// não seja lista vira lista vazia.
  static List<WineMatchReasonModel> tryParseList(dynamic value) {
    final list = JsonUtils.asList(value);
    if (list == null) return const [];
    return list
        .map(tryParse)
        .whereType<WineMatchReasonModel>()
        .toList(growable: false);
  }

  WineMatchReason toEntity() => WineMatchReason(
        code: code,
        value: value,
        positive: positive,
      );
}
