import 'package:essentials/essentials.dart';
import 'package:flutter/material.dart';

/// Traduz o tipo de vinho vindo da API ("Red", "White", "Sparkling", "Rosé",
/// "Dessert", "Dessert/Port") usando as chaves `wine_type_*` do i18n.
/// Tipos desconhecidos são exibidos como vieram.
String? wineTypeLabel(BuildContext context, String? type) {
  final raw = type?.trim();
  if (raw == null || raw.isEmpty) return null;

  final normalized = raw
      .toLowerCase()
      .replaceAll('é', 'e')
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
  final key = 'wine_type_$normalized';
  final translated = getString(context, key);
  // getString devolve a própria chave quando ela não existe.
  return translated == key ? raw : translated;
}
