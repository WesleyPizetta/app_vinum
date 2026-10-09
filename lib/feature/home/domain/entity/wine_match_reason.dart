/// Um motivo de "por que este vinho combina com você", como vem da API em
/// `reasons: [{"code", "value", "positive"}]` (positivos primeiro).
///
/// [code] é mantido como `String`: códigos desconhecidos não quebram o parse
/// e são ignorados pela apresentação. Os códigos conhecidos estão em
/// [WineMatchReasonCode].
class WineMatchReason {
  final String code;

  /// Valor opcional (tipo, corpo, acidez, chave de comida ou nome de vinho,
  /// conforme o [code]).
  final String? value;
  final bool positive;

  const WineMatchReason({
    required this.code,
    this.value,
    this.positive = true,
  });

  @override
  bool operator ==(Object other) =>
      other is WineMatchReason &&
      other.code == code &&
      other.value == value &&
      other.positive == positive;

  @override
  int get hashCode => Object.hash(code, value, positive);
}

/// Códigos de [WineMatchReason.code] conhecidos pelo app.
class WineMatchReasonCode {
  WineMatchReasonCode._();

  /// `value`: tipo do vinho (ex.: "Red").
  static const String typeMatch = 'type_match';

  /// `value`: tipo do vinho, diferente do preferido.
  static const String typeOther = 'type_other';

  /// `value`: corpo do vinho (ex.: "Full-bodied").
  static const String bodyMatch = 'body_match';
  static const String bodyLighter = 'body_lighter';
  static const String bodyFuller = 'body_fuller';

  /// `value`: acidez ("High", "Medium", "Low").
  static const String acidityMatch = 'acidity_match';
  static const String acidityLower = 'acidity_lower';
  static const String acidityHigher = 'acidity_higher';

  /// `value`: chave de comida (`meat`, `poultry`, ...).
  static const String pairsWith = 'pairs_with';

  /// `value`: nome de um vinho que o usuário curtiu.
  static const String similarTo = 'similar_to';
}
