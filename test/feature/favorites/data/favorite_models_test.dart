import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:vinum/feature/favorites/data/model/favorite_ids_model.dart';
import 'package:vinum/feature/favorites/data/model/favorite_wines_page_model.dart';

void main() {
  group('FavoriteIdsModel.tryParse', () {
    test('faz o parse de wine_ids e descarta inválidos', () {
      final ids = FavoriteIdsModel.tryParse({
        'wine_ids': [100003, '108705', 100003, null, '', 1.5],
      });
      expect(ids, {'100003', '108705'});
    });

    test('aceita o corpo como String JSON', () {
      expect(
        FavoriteIdsModel.tryParse(jsonEncode({'wine_ids': [1, 2]})),
        {'1', '2'},
      );
    });

    test('lista vazia é válida', () {
      expect(FavoriteIdsModel.tryParse({'wine_ids': []}), isEmpty);
    });

    test('retorna null fora do contrato', () {
      expect(FavoriteIdsModel.tryParse(null), isNull);
      expect(FavoriteIdsModel.tryParse('not json'), isNull);
      expect(FavoriteIdsModel.tryParse({'wine_ids': 'x'}), isNull);
      expect(FavoriteIdsModel.tryParse([1, 2]), isNull);
    });
  });

  group('FavoriteStatusModel.readIsFavorite', () {
    test('lê is_favorite', () {
      expect(
        FavoriteStatusModel.readIsFavorite(
            {'wine_id': 100003, 'is_favorite': true}),
        isTrue,
      );
      expect(
        FavoriteStatusModel.readIsFavorite(
            '{"wine_id": 100003, "is_favorite": false}'),
        isFalse,
      );
    });

    test('ausente ou inválido -> null', () {
      expect(FavoriteStatusModel.readIsFavorite({'wine_id': 1}), isNull);
      expect(FavoriteStatusModel.readIsFavorite(null), isNull);
      expect(FavoriteStatusModel.readIsFavorite(''), isNull);
    });
  });

  group('FavoriteWinesPageModel.tryParse', () {
    final contractBody = <String, dynamic>{
      'favorites': [
        {
          'wine_id': 100003,
          'name': 'Cabernet Sauvignon',
          'type': 'Red',
          'elaborate': 'Varietal/100%',
          'body': 'Full-bodied',
          'acidity': 'High',
          'abv': 12.0,
          'country': 'Brazil',
          'region': 'Serra Gaúcha',
          'winery': 'Castellamare',
          'website': null,
          'grapes': ['Cabernet Sauvignon'],
          'harmonize': ['Beef', 'Lamb'],
          'vintages': [2018, 2020, 2019],
          'avg_rating': 8.5,
          'rating_count': 2,
          'favorited_at': '2026-09-28T19:39:13Z',
        },
        {
          'wine_id': '108705',
          'name': 'Espumante Brut',
          'type': 'Sparkling',
          'avg_rating': null,
          'rating_count': 0,
          'favorited_at': 'ontem',
        },
        {'name': 'Sem id'},
      ],
      'pagination': {
        'offset': 0,
        'limit': 20,
        'total': 45,
        'has_more': true,
        'next_offset': 20,
      },
    };

    test('faz o parse do contrato e descarta itens inválidos', () {
      final page = FavoriteWinesPageModel.tryParse(contractBody)!.toEntity();

      expect(page.items, hasLength(2));
      final first = page.items.first;
      expect(first.id, '100003');
      expect(first.wine.name, 'Cabernet Sauvignon');
      expect(first.wine.type, 'Red');
      expect(first.wine.description, 'Varietal/100%');
      expect(first.wine.grape, 'Cabernet Sauvignon');
      expect(first.wine.vintage, 2020);
      expect(first.wine.rating, 8.5);
      expect(first.wine.ratingCount, 2);
      expect(first.wine.harmonize, ['Beef', 'Lamb']);
      expect(first.favoritedAt, DateTime.utc(2026, 9, 28, 19, 39, 13));

      final second = page.items[1];
      expect(second.id, '108705');
      expect(second.wine.hasRating, isFalse);
      expect(second.favoritedAt, isNull);

      expect(page.offset, 0);
      expect(page.total, 45);
      expect(page.hasMore, isTrue);
      expect(page.nextOffset, 20);
    });

    test('aceita o corpo como String JSON', () {
      final page =
          FavoriteWinesPageModel.tryParse(jsonEncode(contractBody))!;
      expect(page.items, hasLength(2));
    });

    test('sem pagination -> última página', () {
      final page = FavoriteWinesPageModel.tryParse(
        {
          'favorites': [
            {'wine_id': 1, 'name': 'A'},
          ],
        },
        requestedOffset: 40,
      )!;
      expect(page.offset, 40);
      expect(page.hasMore, isFalse);
      expect(page.nextOffset, isNull);
      expect(page.total, 41);
    });

    test('next_offset inválido usa offset + itens brutos', () {
      final page = FavoriteWinesPageModel.tryParse({
        'favorites': [
          {'wine_id': 1, 'name': 'A'},
          {'name': 'inválido'},
        ],
        'pagination': {'offset': 20, 'has_more': true, 'next_offset': null},
      })!;
      expect(page.hasMore, isTrue);
      expect(page.nextOffset, 22);
    });

    test('lista vazia encerra a paginação', () {
      final page = FavoriteWinesPageModel.tryParse({
        'favorites': [],
        'pagination': {'offset': 0, 'total': 0, 'has_more': true},
      })!;
      expect(page.items, isEmpty);
      expect(page.hasMore, isFalse);
    });

    test('retorna null fora do contrato', () {
      expect(FavoriteWinesPageModel.tryParse(null), isNull);
      expect(FavoriteWinesPageModel.tryParse('not json'), isNull);
      expect(FavoriteWinesPageModel.tryParse({'favorites': 'x'}), isNull);
    });
  });
}
