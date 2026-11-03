import 'package:essentials/essentials.dart';
import 'package:flutter/material.dart';

bool _usesDecimalComma(BuildContext context) =>
    Localizations.maybeLocaleOf(context)?.languageCode != 'en';

/// Nota 0–10 com no máximo uma casa decimal, no formato do idioma
/// ("8,5" em pt, "8.5" em en; "9" quando inteira).
String formatCellarRating(BuildContext context, double value) {
  final rounded = (value * 10).round() / 10;
  final text = rounded == rounded.truncateToDouble()
      ? rounded.toInt().toString()
      : rounded.toStringAsFixed(1);
  return _usesDecimalComma(context) ? text.replaceAll('.', ',') : text;
}

/// "8,5/10" (chave `cellar_rating_value`).
String formatCellarRatingOutOfTen(BuildContext context, double value) =>
    getString(context, 'cellar_rating_value')
        .replaceAll('{value}', formatCellarRating(context, value));

/// Data local curta: dd/MM/aaaa (pt) ou MM/dd/aaaa (en).
String formatCellarDate(BuildContext context, DateTime date) {
  final local = date.toLocal();
  String two(int value) => value.toString().padLeft(2, '0');
  final isEnglish = Localizations.maybeLocaleOf(context)?.languageCode == 'en';
  return isEnglish
      ? '${two(local.month)}/${two(local.day)}/${local.year}'
      : '${two(local.day)}/${two(local.month)}/${local.year}';
}
