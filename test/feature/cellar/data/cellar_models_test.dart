import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:vinum/feature/cellar/data/model/cellar_review_model.dart';
import 'package:vinum/feature/cellar/data/model/cellar_reviews_page_model.dart';

void main() {
  group('CellarReviewModel.tryParse', () {
    test('faz o parse do contrato com o vinho embutido', () {
      final review = CellarReviewModel.tryParse({
        'id': '0b6f3c1e-1d2a-4b7a-9c55-6a1f6f0d2a10',
        'wine_id': 12,
        'nota': 8.5,
        'comentario': '  Muito bom  ',
        'tags': ['frutado', '', 'SECO'],
        'created_at': '2026-09-30T12:00:00Z',
        'wine': {
          'wine_id': 12,
          'name': 'Malbec Reserva',
          'type': 'Red',
          'winery': 'Bodega X',
          'grapes': ['Malbec'],
          'vintages': [2019, 2021],
          'avg_rating': 8.1,
          'rating_count': 3,
        },
      })!.toEntity();

      expect(review.id, '0b6f3c1e-1d2a-4b7a-9c55-6a1f6f0d2a10');
      expect(review.wineId, '12');
      expect(review.rating, 8.5);
      expect(review.comment, 'Muito bom');
      expect(review.tags, ['frutado', 'SECO']);
      expect(review.createdAt, DateTime.utc(2026, 9, 30, 12));
      expect(review.wine?.name, 'Malbec Reserva');
      expect(review.wine?.type, 'Red');
      expect(review.wine?.vintage, 2021);
    });

    test('vinho null mantém o wine_id para abrir o detalhe', () {
      final review = CellarReviewModel.tryParse({
        'id': 'r1',
        'wine_id': 42,
        'nota': 7,
        'comentario': '',
        'tags': null,
        'created_at': 'ontem',
        'wine': null,
      })!;

      expect(review.wineId, '42');
      expect(review.wine, isNull);
      expect(review.rating, 7.0);
      expect(review.comment, isNull);
      expect(review.tags, isEmpty);
      expect(review.createdAt, isNull);
    });

    test('sem wine_id usa o id do vinho embutido', () {
      final review = CellarReviewModel.tryParse({
        'id': 'r1',
        'nota': '6.5',
        'wine': {'wine_id': 99, 'name': 'Rosé'},
      })!;
      expect(review.wineId, '99');
      expect(review.rating, 6.5);
    });

    test('nota fora de 0–10 é limitada', () {
      expect(
        CellarReviewModel.tryParse({'id': 'a', 'wine_id': 1, 'nota': 12})!
            .rating,
        10.0,
      );
      expect(
        CellarReviewModel.tryParse({'id': 'b', 'wine_id': 1, 'nota': -1})!
            .rating,
        0.0,
      );
    });

    test('retorna null sem id, wine_id ou nota', () {
      expect(CellarReviewModel.tryParse({'wine_id': 1, 'nota': 8}), isNull);
      expect(CellarReviewModel.tryParse({'id': 'a', 'nota': 8}), isNull);
      expect(CellarReviewModel.tryParse({'id': 'a', 'wine_id': 1}), isNull);
      expect(
        CellarReviewModel.tryParse({'id': 'a', 'wine_id': 1, 'nota': 'x'}),
        isNull,
      );
      expect(CellarReviewModel.tryParse(null), isNull);
      expect(CellarReviewModel.tryParse('not json'), isNull);
    });
  });

  group('CellarReviewsPageModel.tryParse', () {
    final contractBody = <String, dynamic>{
      'reviews': [
        {
          'id': 'r1',
          'wine_id': 12,
          'nota': 8.5,
          'comentario': 'Ótimo',
          'tags': ['frutado'],
          'created_at': '2026-09-30T12:00:00Z',
          'wine': {'wine_id': 12, 'name': 'Malbec Reserva', 'type': 'Red'},
        },
        {
          'id': 'r2',
          'wine_id': 13,
          'nota': 6,
          'comentario': null,
          'tags': [],
          'created_at': '2026-09-29T12:00:00Z',
          'wine': null,
        },
        {'id': 'sem nota', 'wine_id': 1},
      ],
      'pagination': {
        'offset': 0,
        'limit': 20,
        'has_more': true,
        'next_offset': 20,
      },
    };

    test('faz o parse do contrato e descarta itens inválidos', () {
      final page = CellarReviewsPageModel.tryParse(contractBody)!.toEntity();

      expect(page.items.map((r) => r.id), ['r1', 'r2']);
      expect(page.items.first.wine?.name, 'Malbec Reserva');
      expect(page.items[1].wine, isNull);
      expect(page.offset, 0);
      expect(page.hasMore, isTrue);
      expect(page.nextOffset, 20);
    });

    test('aceita o corpo como String JSON', () {
      final page = CellarReviewsPageModel.tryParse(jsonEncode(contractBody))!;
      expect(page.items, hasLength(2));
    });

    test('sem pagination -> última página', () {
      final page = CellarReviewsPageModel.tryParse(
        {
          'reviews': [
            {'id': 'r1', 'wine_id': 1, 'nota': 8},
          ],
        },
        requestedOffset: 40,
      )!;
      expect(page.offset, 40);
      expect(page.hasMore, isFalse);
      expect(page.nextOffset, isNull);
    });

    test('next_offset inválido usa offset + itens brutos', () {
      final page = CellarReviewsPageModel.tryParse({
        'reviews': [
          {'id': 'r1', 'wine_id': 1, 'nota': 8},
          {'id': 'inválido'},
        ],
        'pagination': {'offset': 20, 'has_more': true, 'next_offset': null},
      })!;
      expect(page.hasMore, isTrue);
      expect(page.nextOffset, 22);
    });

    test('lista vazia encerra a paginação', () {
      final page = CellarReviewsPageModel.tryParse({
        'reviews': [],
        'pagination': {'offset': 0, 'has_more': true},
      })!;
      expect(page.items, isEmpty);
      expect(page.hasMore, isFalse);
    });

    test('retorna null fora do contrato', () {
      expect(CellarReviewsPageModel.tryParse(null), isNull);
      expect(CellarReviewsPageModel.tryParse('not json'), isNull);
      expect(CellarReviewsPageModel.tryParse({'reviews': 'x'}), isNull);
      expect(CellarReviewsPageModel.tryParse([1, 2]), isNull);
    });
  });
}
