import 'dart:math' as math;

import 'package:flutter/services.dart';

import '../../domain/nickname_rules.dart';

/// Enquanto o usuário digita: minúsculas, sem acentos e somente
/// `[a-z0-9_.]` (espaços, "@" e outros símbolos são descartados). O "@" é
/// mostrado como prefixo fixo do campo.
class NicknameInputFormatter extends TextInputFormatter {
  const NicknameInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    final sanitized = NicknameRules.sanitizeInput(text);
    if (sanitized == text) return newValue;

    // Mantém o cursor na mesma posição relativa ao texto filtrado.
    final cursor = newValue.selection.isValid
        ? math.min(math.max(newValue.selection.extentOffset, 0), text.length)
        : text.length;
    final before = NicknameRules.sanitizeInput(text.substring(0, cursor));
    final offset = math.min(before.length, sanitized.length);
    return TextEditingValue(
      text: sanitized,
      selection: TextSelection.collapsed(offset: offset),
    );
  }
}
