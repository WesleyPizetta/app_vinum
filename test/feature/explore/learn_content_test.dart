import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:vinum/feature/explore/domain/entity/daily_tip.dart';
import 'package:vinum/feature/explore/domain/entity/learn_topic.dart';

Map<String, dynamic> _readLang(String file) =>
    jsonDecode(File('lang/$file').readAsStringSync()) as Map<String, dynamic>;

void main() {
  group('LearnTopic', () {
    test('nomes estáveis (usados por outras telas)', () {
      expect(
        LearnTopic.values.map((t) => t.name),
        ['body', 'acidity', 'tannins', 'types', 'pairing', 'vintage', 'grapes'],
      );
    });

    test('chaves do conteúdo seguem o padrão learn_<tópico>_*', () {
      expect(LearnTopic.body.titleKey, 'learn_body_title');
      expect(LearnTopic.body.summaryKey, 'learn_body_summary');
      expect(LearnTopic.body.introKey, 'learn_body_intro');
      expect(LearnTopic.body.tipKey, 'learn_body_tip');
      expect(LearnTopic.grapes.pointKeys.first, 'learn_grapes_point_1');
      for (final topic in LearnTopic.values) {
        expect(topic.pointKeys.length, inInclusiveRange(3, 6));
      }
    });

    for (final file in ['pt_BR.json', 'en_US.json']) {
      test('todas as chaves existem em $file', () {
        final lang = _readLang(file);
        final keys = <String>[
          for (final topic in LearnTopic.values) ...[
            topic.titleKey,
            topic.summaryKey,
            topic.introKey,
            topic.tipKey,
            ...topic.pointKeys,
          ],
          for (final tip in DailyTip.all) tip.textKey,
        ];
        final missing = keys.where((k) => !lang.containsKey(k)).toList();
        expect(missing, isEmpty);
      });
    }
  });

  group('DailyTip.forDay', () {
    test('mesma dica durante o dia todo', () {
      final morning = DailyTip.forDay(DateTime(2026, 10, 1, 0, 5));
      final night = DailyTip.forDay(DateTime(2026, 10, 1, 23, 55));
      expect(identical(morning, night), isTrue);
    });

    test('troca a cada dia e percorre todas as dicas', () {
      final start = DateTime(2026, 10, 1);
      final tips = [
        for (var i = 0; i < DailyTip.all.length; i++)
          DailyTip.forDay(DateTime(start.year, start.month, start.day + i)),
      ];
      expect(tips.map((t) => t.textKey).toSet(), hasLength(DailyTip.all.length));
    });
  });
}
