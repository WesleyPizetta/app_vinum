import 'package:flutter_test/flutter_test.dart';
import 'package:vinum/core/utils/relative_time.dart';

const _pt = {
  'time_ago_now': 'agora mesmo',
  'time_ago_minute': '1 minuto atrás',
  'time_ago_minutes': '{n} minutos atrás',
  'time_ago_hour': '1 hora atrás',
  'time_ago_hours': '{n} horas atrás',
  'time_ago_day': '1 dia atrás',
  'time_ago_days': '{n} dias atrás',
  'time_ago_week': '1 semana atrás',
  'time_ago_weeks': '{n} semanas atrás',
  'time_ago_month': '1 mês atrás',
  'time_ago_months': '{n} meses atrás',
  'time_ago_year': '1 ano atrás',
  'time_ago_years': '{n} anos atrás',
};

void main() {
  final now = DateTime.utc(2026, 10, 9, 12);
  String label(Duration ago) => formatRelativeTime(
        now.subtract(ago),
        now: now,
        translate: (key) => _pt[key]!,
      );

  test('formata o tempo decorrido em português', () {
    expect(label(const Duration(seconds: 20)), 'agora mesmo');
    expect(label(const Duration(minutes: 1)), '1 minuto atrás');
    expect(label(const Duration(minutes: 2)), '2 minutos atrás');
    expect(label(const Duration(hours: 3)), '3 horas atrás');
    expect(label(const Duration(days: 1)), '1 dia atrás');
    expect(label(const Duration(days: 5)), '5 dias atrás');
    expect(label(const Duration(days: 14)), '2 semanas atrás');
    expect(label(const Duration(days: 65)), '2 meses atrás');
    expect(label(const Duration(days: 365)), '1 ano atrás');
    expect(label(const Duration(days: 800)), '2 anos atrás');
  });

  test('data no futuro (relógio adiantado) vira "agora mesmo"', () {
    expect(label(const Duration(minutes: -5)), 'agora mesmo');
  });
}
