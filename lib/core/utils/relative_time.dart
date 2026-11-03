import 'package:essentials/essentials.dart';
import 'package:flutter/widgets.dart';

/// Texto relativo ao estilo "2 minutos atrás", "5 dias atrás", "1 ano atrás".
String relativeTimeLabel(BuildContext context, DateTime date, {DateTime? now}) {
  return formatRelativeTime(
    date,
    now: now,
    translate: (key) => getString(context, key),
  );
}

/// Versão pura de [relativeTimeLabel], testável sem `BuildContext`.
///
/// [translate] recebe uma chave de i18n (`time_ago_*`); as chaves no plural
/// usam o marcador `{n}`.
String formatRelativeTime(
  DateTime date, {
  DateTime? now,
  required String Function(String key) translate,
}) {
  var diff = (now ?? DateTime.now()).difference(date);
  // Relógio do aparelho atrasado em relação ao servidor: trata como "agora".
  if (diff.isNegative) diff = Duration.zero;

  String unit(int n, String singularKey, String pluralKey) => n == 1
      ? translate(singularKey)
      : translate(pluralKey).replaceAll('{n}', '$n');

  final days = diff.inDays;
  if (diff.inMinutes < 1) return translate('time_ago_now');
  if (diff.inHours < 1) {
    return unit(diff.inMinutes, 'time_ago_minute', 'time_ago_minutes');
  }
  if (days < 1) return unit(diff.inHours, 'time_ago_hour', 'time_ago_hours');
  if (days < 7) return unit(days, 'time_ago_day', 'time_ago_days');
  if (days < 30) return unit(days ~/ 7, 'time_ago_week', 'time_ago_weeks');
  if (days < 365) {
    final months = days ~/ 30;
    return unit(months < 1 ? 1 : months, 'time_ago_month', 'time_ago_months');
  }
  return unit(days ~/ 365, 'time_ago_year', 'time_ago_years');
}
