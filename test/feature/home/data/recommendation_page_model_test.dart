import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:vinum/feature/home/data/model/recommendation_page_model.dart';
import 'package:vinum/feature/home/domain/entity/food_category.dart';

Map<String, dynamic> _wine(int id, {String? name}) => {
      'wine_id': id,
      'name': name ?? 'Vinho $id',
      'type': 'Red',
      'match_percent': 90,
      'avg_rating': null,
      'rating_count': 0,
    };

void main() {
  group('RecommendationPageModel.tryParse', () {
    test('faz o parse de recommendations + pagination', () {
      final body = {
        'source': 'quiz',
        'food': 'meat',
        'recommendations': [_wine(1), _wine(2)],
        'pagination': {
          'offset': 0,
          'limit': 20,
          'total': 143,
          'has_more': true,
          'next_offset': 20,
        },
      };

      final page = RecommendationPageModel.tryParse(body)!;

      expect(page.items.map((w) => w.wineId), ['1', '2']);
      expect(page.offset, 0);
      expect(page.total, 143);
      expect(page.hasMore, isTrue);
      expect(page.nextOffset, 20);

      final entity = page.toEntity();
      expect(entity.items.first.id, '1');
      expect(entity.hasMore, isTrue);
      expect(entity.nextOffset, 20);
    });

    test('aceita o corpo como String JSON', () {
      final body = jsonEncode({
        'recommendations': [_wine(1)],
        'pagination': {
          'offset': 20,
          'limit': 20,
          'total': 21,
          'has_more': false,
          'next_offset': null,
        },
      });

      final page = RecommendationPageModel.tryParse(body)!;
      expect(page.items, hasLength(1));
      expect(page.offset, 20);
      expect(page.hasMore, isFalse);
      expect(page.nextOffset, isNull);
    });

    test('sem pagination -> última página (hasMore false)', () {
      final page = RecommendationPageModel.tryParse(
        {
          'recommendations': [_wine(1), _wine(2)],
        },
        requestedOffset: 40,
      )!;

      expect(page.hasMore, isFalse);
      expect(page.nextOffset, isNull);
      expect(page.offset, 40);
      expect(page.total, 42);
    });

    test('pagination inválida -> última página', () {
      final page = RecommendationPageModel.tryParse({
        'recommendations': [_wine(1)],
        'pagination': 'x',
      })!;
      expect(page.hasMore, isFalse);
      expect(page.nextOffset, isNull);
    });

    test('has_more sem next_offset calcula pelo tamanho bruto da página', () {
      final page = RecommendationPageModel.tryParse({
        // O item sem nome é descartado, mas conta para o offset do servidor.
        'recommendations': [_wine(1), {'wine_id': 2}, _wine(3)],
        'pagination': {'offset': 20, 'has_more': true},
      })!;

      expect(page.items, hasLength(2));
      expect(page.hasMore, isTrue);
      expect(page.nextOffset, 23);
    });

    test('lista vazia nunca tem próxima página', () {
      final page = RecommendationPageModel.tryParse({
        'recommendations': [],
        'pagination': {'offset': 0, 'has_more': true, 'next_offset': 20},
      })!;
      expect(page.items, isEmpty);
      expect(page.hasMore, isFalse);
      expect(page.nextOffset, isNull);
    });

    test('retorna null fora do contrato', () {
      expect(RecommendationPageModel.tryParse(null), isNull);
      expect(RecommendationPageModel.tryParse('not json'), isNull);
      expect(
        RecommendationPageModel.tryParse({'recommendations': 'x'}),
        isNull,
      );
    });
  });

  group('FoodCategory', () {
    test('apiValue segue o contrato', () {
      expect(
        FoodCategory.values.map((c) => c.apiValue),
        [
          'meat',
          'poultry',
          'pork',
          'seafood',
          'pasta',
          'cheese',
          'vegetarian',
          'appetizer',
          'dessert',
        ],
      );
    });

    test('fromApiValue', () {
      expect(FoodCategory.fromApiValue('Meat'), FoodCategory.meat);
      expect(FoodCategory.fromApiValue(' seafood '), FoodCategory.seafood);
      expect(FoodCategory.fromApiValue('sushi'), isNull);
      expect(FoodCategory.fromApiValue(null), isNull);
    });
  });
}
