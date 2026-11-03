import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:vinum/feature/home/data/model/recommended_wine_model.dart';

void main() {
  final contractBody = <String, dynamic>{
    'source': 'quiz',
    'profile': {'acidity_score': 3, 'body_score': 1, 'preferred_type': 'Red'},
    'recommendations': [
      {
        'wine_id': 100003,
        'name': 'Cabernet Sauvignon',
        'type': 'Red',
        'body': 'Full-bodied',
        'acidity': 'High',
        'abv': 12.0,
        'country': 'Brazil',
        'region': 'Serra Gaúcha',
        'winery': 'Castellamare',
        'grapes': ['Cabernet Sauvignon'],
        'harmonize': ['Beef', 'Lamb'],
        'match_percent': 93,
        'avg_rating': 8.5,
        'rating_count': 2,
        'is_favorite': true,
      },
      {
        'wine_id': '100004',
        'name': 'Espumante Brut',
        'type': 'Sparkling',
        'abv': null,
        'grapes': ['Chardonnay', 1, ''],
        'match_percent': 71.6,
        'avg_rating': null,
        'rating_count': 0,
      },
      {'name': 'Sem id'},
    ],
  };

  group('RecommendedWineModel.tryParseList', () {
    test('faz o parse do contrato (Map) e descarta itens inválidos', () {
      final models = RecommendedWineModel.tryParseList(contractBody)!;

      expect(models, hasLength(2));
      final first = models.first;
      expect(first.wineId, '100003');
      expect(first.type, 'Red');
      expect(first.region, 'Serra Gaúcha');
      expect(first.grapes, ['Cabernet Sauvignon']);
      expect(first.harmonize, ['Beef', 'Lamb']);
      expect(first.matchPercent, 93);
      expect(first.avgRating, 8.5);
      expect(first.ratingCount, 2);
      expect(first.isFavorite, isTrue);
      expect(first.toEntity().isFavorite, isTrue);

      final second = models[1];
      expect(second.wineId, '100004');
      expect(second.abv, isNull);
      expect(second.grapes, ['Chardonnay']);
      expect(second.matchPercent, 72);
      expect(second.avgRating, isNull);
      // Sem `is_favorite` -> false.
      expect(second.isFavorite, isFalse);
    });

    test('aceita o corpo como String JSON', () {
      final models =
          RecommendedWineModel.tryParseList(jsonEncode(contractBody))!;
      expect(models, hasLength(2));
    });

    test('retorna null fora do contrato', () {
      expect(RecommendedWineModel.tryParseList(null), isNull);
      expect(RecommendedWineModel.tryParseList('not json'), isNull);
      expect(RecommendedWineModel.tryParseList({'recommendations': 'x'}),
          isNull);
    });

    test('lista vazia é válida', () {
      expect(
        RecommendedWineModel.tryParseList({'recommendations': []}),
        isEmpty,
      );
    });
  });

  test('toEntity mapeia nota nula e afinidade', () {
    final entity =
        RecommendedWineModel.tryParseList(contractBody)![1].toEntity();
    expect(entity.id, '100004');
    expect(entity.rating, isNull);
    expect(entity.hasRating, isFalse);
    expect(entity.affinityPercentage, 72);
    expect(entity.isFavorite, isFalse);
  });
}
