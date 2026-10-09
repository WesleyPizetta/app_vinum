import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:vinum/feature/wine/data/model/wine_highlights_model.dart';

void main() {
  Map<String, dynamic> wine(int id, {int ratingCount = 3}) => {
        'wine_id': id,
        'name': 'Vinho $id',
        'type': 'Red',
        'elaborate': 'Varietal/100%',
        'body': 'Full-bodied',
        'acidity': 'High',
        'abv': 13.5,
        'country': 'Argentina',
        'region': 'Mendoza',
        'winery': 'Bodega',
        'website': null,
        'grapes': ['Malbec'],
        'harmonize': ['Beef'],
        'vintages': [2019, 2020],
        'avg_rating': 8.7,
        'rating_count': ratingCount,
      };

  group('WineHighlightsModel.tryParse', () {
    test('faz o parse da semana e dos vinhos (Map ou String JSON)', () {
      final body = {
        'week': '2026-W40',
        'wines': [
          wine(1),
          wine(2, ratingCount: 0),
          wine(1),
          {'name': 'sem id'},
        ],
      };

      for (final raw in [body, jsonEncode(body)]) {
        final highlights = WineHighlightsModel.tryParse(raw)!.toEntity();
        expect(highlights.week, '2026-W40');
        // Inválidos e repetidos são descartados.
        expect(highlights.wines.map((w) => w.id), ['1', '2']);
        expect(highlights.wines.first.rating, 8.7);
        expect(highlights.wines.first.hasRating, isTrue);
        expect(highlights.wines.first.type, 'Red');
        expect(highlights.wines.first.vintage, 2020);
        // Sem avaliações: nota zerada.
        expect(highlights.wines[1].hasRating, isFalse);
        expect(highlights.wines[1].rating, 0);
      }
    });

    test('sem week -> vazio', () {
      final highlights = WineHighlightsModel.tryParse({'wines': []})!;
      expect(highlights.week, '');
      expect(highlights.wines, isEmpty);
    });

    test('retorna null fora do contrato', () {
      expect(WineHighlightsModel.tryParse(null), isNull);
      expect(WineHighlightsModel.tryParse('not json'), isNull);
      expect(WineHighlightsModel.tryParse({'week': '2026-W40'}), isNull);
      expect(WineHighlightsModel.tryParse([wine(1)]), isNull);
    });
  });
}
