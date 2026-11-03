import 'package:essentials/essentials.dart';
import 'package:flutter/material.dart';

import '../../../wine/presentation/widget/wine_labels.dart';
import '../../domain/entity/food_category.dart';
import '../../domain/entity/wine_match_reason.dart';
import 'food_category_labels.dart';
import 'wine_type_label.dart';

/// Frase localizada para um motivo de recomendação, ex.:
/// "Tinto, seu tipo favorito", "Encorpado, como você gosta",
/// "Mais leve do que você costuma preferir", "Harmoniza com carnes",
/// "Parecido com Malbec X, que você curtiu".
///
/// Retorna `null` para códigos desconhecidos (o motivo deve ser ignorado).
String? matchReasonSentence(BuildContext context, WineMatchReason reason) {
  final trimmed = reason.value?.trim();
  final value = trimmed == null || trimmed.isEmpty ? null : trimmed;

  /// Frase com `{placeholder}` preenchido por um rótulo traduzido (em
  /// minúsculas, para caber no meio da frase); sem valor usa [genericKey].
  String withLabel(
    String key,
    String genericKey,
    String placeholder,
    String? Function(String raw) label,
  ) {
    final translated = value == null ? null : label(value);
    if (translated == null || translated.isEmpty) {
      return getString(context, genericKey);
    }
    return _capitalize(
      getString(context, key)
          .replaceAll(placeholder, translated.toLowerCase()),
    );
  }

  switch (reason.code) {
    case WineMatchReasonCode.typeMatch:
      return withLabel(
        'reason_type_match',
        'reason_type_match_generic',
        '{type}',
        (raw) => wineTypeLabel(context, raw),
      );
    case WineMatchReasonCode.typeOther:
      return withLabel(
        'reason_type_other',
        'reason_type_other_generic',
        '{type}',
        (raw) => wineTypeLabel(context, raw),
      );
    case WineMatchReasonCode.bodyMatch:
      return withLabel(
        'reason_body_match',
        'reason_body_match_generic',
        '{body}',
        (raw) => translateWineLabel(context, 'wine_body', raw),
      );
    case WineMatchReasonCode.bodyLighter:
      return getString(context, 'reason_body_lighter');
    case WineMatchReasonCode.bodyFuller:
      return getString(context, 'reason_body_fuller');
    case WineMatchReasonCode.acidityMatch:
      return withLabel(
        'reason_acidity_match',
        'reason_acidity_match_generic',
        '{acidity}',
        (raw) => translateWineLabel(context, 'wine_level', raw),
      );
    case WineMatchReasonCode.acidityLower:
      return getString(context, 'reason_acidity_lower');
    case WineMatchReasonCode.acidityHigher:
      return getString(context, 'reason_acidity_higher');
    case WineMatchReasonCode.pairsWith:
      final food = FoodCategory.fromApiValue(value);
      return getString(
        context,
        food?.pairsWithReasonKey ?? 'reason_pairs_with_generic',
      );
    case WineMatchReasonCode.similarTo:
      // Nome do vinho: mantido como veio (sem minúsculas).
      if (value == null) {
        return getString(context, 'reason_similar_to_generic');
      }
      return getString(context, 'reason_similar_to')
          .replaceAll('{wine}', value);
    default:
      return null;
  }
}

String _capitalize(String text) {
  if (text.isEmpty) return text;
  return text[0].toUpperCase() + text.substring(1);
}
