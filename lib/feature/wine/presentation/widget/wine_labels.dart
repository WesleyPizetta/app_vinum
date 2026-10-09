import 'package:essentials/essentials.dart';
import 'package:flutter/material.dart';

/// Traduz um rótulo vindo da base (em inglês) usando `prefix_<normalizado>`
/// no i18n. Sem tradução, devolve o texto original.
String translateWineLabel(BuildContext context, String prefix, String raw) {
  final value = raw.trim();
  if (value.isEmpty) return value;
  final normalized = value
      .toLowerCase()
      .replaceAll('é', 'e')
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
  final key = '${prefix}_$normalized';
  final translated = getString(context, key);
  // getString devolve a própria chave quando ela não existe.
  return translated == key ? value : translated;
}
