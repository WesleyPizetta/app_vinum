import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:vinum/feature/home/data/model/recommended_wine_model.dart';
import 'package:vinum/feature/home/data/model/search_result_model.dart';
import 'package:vinum/feature/home/data/model/wine_match_model.dart';
import 'package:vinum/feature/home/data/model/wine_match_reason_model.dart';
import 'package:vinum/feature/home/domain/entity/food_category.dart';
import 'package:vinum/feature/home/domain/entity/wine_match_reason.dart';

void main() {
  group('WineMatchReasonModel.tryParseList', () {
    test('faz o parse, normaliza o código e descarta itens inválidos', () {
      final reasons = WineMatchReasonModel.tryParseList([
        {'code': 'type_match', 'value': 'Red', 'positive': true},
        {'code': ' PAIRS_WITH ', 'value': 'meat'},
        {'code': 'body_lighter', 'value': '', 'positive': false},
        {'code': 'future_code', 'positive': true},
        {'value': 'sem código'},
        'lixo',
        null,
      ]);

      expect(reasons.map((r) => r.code),
          ['type_match', 'pairs_with', 'body_lighter', 'future_code']);
      expect(reasons[0].value, 'Red');
      expect(reasons[0].positive, isTrue);
      // Sem `positive` -> true.
      expect(reasons[1].positive, isTrue);
      // Valor vazio -> null.
      expect(reasons[2].value, isNull);
      expect(reasons[2].positive, isFalse);
      expect(
        reasons[0].toEntity(),
        const WineMatchReason(code: 'type_match', value: 'Red'),
      );
    });

    test('valor que não é lista -> lista vazia', () {
      expect(WineMatchReasonModel.tryParseList(null), isEmpty);
      expect(WineMatchReasonModel.tryParseList({'code': 'x'}), isEmpty);
    });
  });

  group('RecommendedWineModel reasons', () {
    test('item com reasons -> entidade com os motivos na ordem da API', () {
      final model = RecommendedWineModel.tryParse({
        'wine_id': 1,
        'name': 'Malbec',
        'match_percent': 88,
        'reasons': [
          {'code': 'type_match', 'value': 'Red', 'positive': true},
          {'code': 'similar_to', 'value': 'Malbec X', 'positive': true},
          {'code': 'acidity_higher', 'value': 'High', 'positive': false},
        ],
      })!;

      final entity = model.toEntity();
      expect(entity.reasons.map((r) => r.code),
          ['type_match', 'similar_to', 'acidity_higher']);
      expect(entity.reasons[1].value, 'Malbec X');
      expect(entity.reasons.last.positive, isFalse);
      // copyWith preserva os motivos.
      expect(entity.copyWith(isFavorite: true).reasons, entity.reasons);
    });

    test('sem reasons -> lista vazia', () {
      final model = RecommendedWineModel.tryParse(
        {'wine_id': 1, 'name': 'Malbec', 'match_percent': 88},
      )!;
      expect(model.toEntity().reasons, isEmpty);
    });
  });

  group('WineMatchModel.tryParse', () {
    final body = {
      'wine_id': 1,
      'match_percent': 86.6,
      'is_favorite': true,
      'reasons': [
        {'code': 'body_match', 'value': 'Full-bodied', 'positive': true},
        {'code': 'type_other', 'value': 'White', 'positive': false},
      ],
      'effective_profile': {
        'body_score': 2.3,
        'acidity_score': 2.0,
        'preferred_type': 'Red',
        'quiz_weight': 1,
        'signals': {'liked': 2, 'favorites': 1, 'disliked': 0},
      },
    };

    test('faz o parse do contrato (Map ou String JSON)', () {
      for (final raw in [body, jsonEncode(body)]) {
        final match = WineMatchModel.tryParse(raw)!.toEntity();
        expect(match.wineId, '1');
        expect(match.matchPercent, 87);
        expect(match.isFavorite, isTrue);
        expect(match.reasons, hasLength(2));
        expect(match.reasons.first.code, 'body_match');
        expect(match.reasons.last.positive, isFalse);
      }
    });

    test('usa o id pedido quando a resposta não traz wine_id', () {
      final match = WineMatchModel.tryParse(
        {'match_percent': 140},
        requestedWineId: '42',
      )!;
      expect(match.wineId, '42');
      expect(match.matchPercent, 100);
      expect(match.reasons, isEmpty);
    });

    test('retorna null fora do contrato', () {
      expect(WineMatchModel.tryParse(null), isNull);
      expect(WineMatchModel.tryParse('not json'), isNull);
      expect(WineMatchModel.tryParse({'wine_id': 1}), isNull);
      expect(WineMatchModel.tryParse({'match_percent': 50}), isNull);
    });
  });

  group('SearchResultModel.tryParse', () {
    Map<String, dynamic> wine(int id) => {
          'wine_id': id,
          'name': 'Vinho $id',
          'type': 'Red',
          'match_percent': 80,
          'avg_rating': null,
          'rating_count': 0,
          'is_favorite': false,
          'reasons': [
            {'code': 'pairs_with', 'value': 'meat', 'positive': true},
          ],
        };

    test('faz o parse de foods, wines e pagination', () {
      final result = SearchResultModel.tryParse({
        'query': 'picanha',
        'foods': [
          {'key': 'meat'},
          {'key': 'unknown'},
          {'key': 'meat'},
          'cheese',
        ],
        'wines': [wine(1), wine(2), {'name': 'sem id'}],
        'pagination': {
          'offset': 0,
          'limit': 20,
          'total': 57,
          'has_more': true,
          'next_offset': 20,
        },
      })!.toEntity();

      expect(result.query, 'picanha');
      expect(result.foods, [FoodCategory.meat, FoodCategory.cheese]);
      expect(result.page.items.map((w) => w.id), ['1', '2']);
      expect(result.page.items.first.reasons.single.value, 'meat');
      expect(result.page.total, 57);
      expect(result.page.hasMore, isTrue);
      expect(result.page.nextOffset, 20);
    });

    test('sem foods/pagination -> sem comidas e última página', () {
      final result = SearchResultModel.tryParse(
        jsonEncode({
          'wines': [wine(1)],
        }),
        requestedQuery: 'malbec',
        requestedOffset: 20,
      )!.toEntity();

      expect(result.query, 'malbec');
      expect(result.foods, isEmpty);
      expect(result.page.offset, 20);
      expect(result.page.hasMore, isFalse);
      expect(result.page.nextOffset, isNull);
    });

    test('retorna null fora do contrato', () {
      expect(SearchResultModel.tryParse(null), isNull);
      expect(SearchResultModel.tryParse({'foods': []}), isNull);
      expect(SearchResultModel.tryParse({'wines': 'x'}), isNull);
    });
  });
}
