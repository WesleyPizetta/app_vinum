import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:essentials/essentials.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vinum/feature/auth/domain/usecase/logout.dart';
import 'package:vinum/feature/favorites/domain/entity/favorite_failure_code.dart';
import 'package:vinum/feature/favorites/domain/entity/favorite_ids.dart';
import 'package:vinum/feature/favorites/domain/entity/favorite_wine.dart';
import 'package:vinum/feature/favorites/domain/entity/favorite_wines_page.dart';
import 'package:vinum/feature/favorites/domain/usecase/get_favorites.dart';
import 'package:vinum/feature/favorites/domain/usecase/set_favorite.dart';
import 'package:vinum/feature/favorites/domain/usecase/watch_favorite_ids.dart';
import 'package:vinum/feature/favorites/presentation/bloc/favorites_list_bloc.dart';
import 'package:vinum/feature/favorites/presentation/bloc/favorites_list_event.dart';
import 'package:vinum/feature/favorites/presentation/bloc/favorites_list_state.dart';
import 'package:vinum/feature/wine/domain/entity/wine.dart';

class MockGetFavorites extends Mock implements GetFavorites {}

class MockSetFavorite extends Mock implements SetFavorite {}

class MockWatchFavoriteIds extends Mock implements WatchFavoriteIds {}

class MockLogout extends Mock implements Logout {}

FavoriteWine _favorite(int id) => FavoriteWine(
      wine: Wine(
        id: '$id',
        name: 'Vinho $id',
        winery: '',
        region: '',
        country: '',
        grape: '',
        vintage: 0,
        rating: 0,
        imageUrl: '',
        description: '',
        type: 'Red',
      ),
      favoritedAt: DateTime.utc(2026, 9, 28),
    );

List<FavoriteWine> _favorites(int from, int count) =>
    List.generate(count, (i) => _favorite(from + i));

Try<FavoriteWinesPage> _page(
  List<FavoriteWine> items, {
  int offset = 0,
  int total = 45,
  bool hasMore = true,
}) =>
    Try.success<FavoriteWinesPage>(FavoriteWinesPage(
      items: items,
      offset: offset,
      total: total,
      hasMore: hasMore,
      nextOffset: hasMore ? offset + items.length : null,
    ));

FavoritesListLoaded _loadedState(
  List<FavoriteWine> items, {
  bool hasMore = false,
  int? nextOffset,
  int? total,
}) =>
    FavoritesListLoaded(
      items: items,
      hasMore: hasMore,
      nextOffset: nextOffset ?? items.length,
      total: total ?? items.length,
    );

TypeMatcher<FavoritesListLoaded> _loaded({
  List<String>? ids,
  bool? hasMore,
  int? total,
  int? nextOffset,
}) {
  var matcher = isA<FavoritesListLoaded>();
  if (ids != null) {
    matcher = matcher.having(
        (s) => s.items.map((f) => f.id).toList(), 'ids', ids);
  }
  if (hasMore != null) {
    matcher = matcher.having((s) => s.hasMore, 'hasMore', hasMore);
  }
  if (total != null) {
    matcher = matcher.having((s) => s.total, 'total', total);
  }
  if (nextOffset != null) {
    matcher = matcher.having((s) => s.nextOffset, 'nextOffset', nextOffset);
  }
  return matcher;
}

List<String> _ids(int from, int count) =>
    List.generate(count, (i) => '${from + i}');

void main() {
  late MockGetFavorites mockGetFavorites;
  late MockSetFavorite mockSetFavorite;
  late MockWatchFavoriteIds mockWatchFavoriteIds;
  late MockLogout mockLogout;
  late StreamController<FavoriteIds> favoritesController;

  /// Respostas por offset pedido.
  late Map<int, Try<FavoriteWinesPage>> responses;

  setUpAll(() {
    registerFallbackValue(const GetFavoritesParams());
    registerFallbackValue(
      const SetFavoriteParams(wineId: '0', isFavorite: false),
    );
  });

  setUp(() {
    mockGetFavorites = MockGetFavorites();
    mockSetFavorite = MockSetFavorite();
    mockWatchFavoriteIds = MockWatchFavoriteIds();
    mockLogout = MockLogout();
    favoritesController = StreamController<FavoriteIds>.broadcast();
    responses = {};

    when(() => mockLogout()).thenAnswer((_) async => Try.success<void>(null));
    when(() => mockWatchFavoriteIds())
        .thenAnswer((_) => favoritesController.stream);
    when(() => mockWatchFavoriteIds.current).thenReturn(FavoriteIds.empty);
    when(() => mockGetFavorites(any())).thenAnswer((invocation) async {
      final params =
          invocation.positionalArguments.first as GetFavoritesParams;
      return responses[params.offset] ??
          Try.reject<FavoriteWinesPage>(UnknownFailure('sem stub'));
    });
  });

  tearDown(() => favoritesController.close());

  FavoritesListBloc buildBloc() => FavoritesListBloc(
        mockGetFavorites,
        mockSetFavorite,
        mockWatchFavoriteIds,
        mockLogout,
      );

  group('FavoritesListStarted', () {
    blocTest<FavoritesListBloc, FavoritesListState>(
      'carrega a primeira página (offset 0, limit 20)',
      build: () {
        responses[0] = _page(_favorites(1, 20));
        return buildBloc();
      },
      act: (bloc) => bloc.add(FavoritesListStarted()),
      expect: () => [
        isA<FavoritesListLoading>(),
        _loaded(ids: _ids(1, 20), hasMore: true, nextOffset: 20, total: 45),
      ],
      verify: (_) {
        final params = verify(() => mockGetFavorites(captureAny()))
            .captured
            .single as GetFavoritesParams;
        expect(params.offset, 0);
        expect(params.limit, FavoritesListBloc.pageSize);
      },
    );

    blocTest<FavoritesListBloc, FavoritesListState>(
      'sem favoritos -> vazio',
      build: () {
        responses[0] = _page(const [], total: 0, hasMore: false);
        return buildBloc();
      },
      act: (bloc) => bloc.add(FavoritesListStarted()),
      expect: () => [
        isA<FavoritesListLoading>(),
        isA<FavoritesListEmpty>(),
      ],
    );

    blocTest<FavoritesListBloc, FavoritesListState>(
      'erro de servidor -> mensagem de servidor',
      build: () {
        responses[0] = Try.reject<FavoriteWinesPage>(
          KnownFailure(FavoriteFailureCode.server, null),
        );
        return buildBloc();
      },
      act: (bloc) => bloc.add(FavoritesListStarted()),
      expect: () => [
        isA<FavoritesListLoading>(),
        isA<FavoritesListError>()
            .having((s) => s.message, 'message', 'favorites_error_server'),
      ],
    );

    blocTest<FavoritesListBloc, FavoritesListState>(
      'falha de conexão -> mensagem de conexão',
      build: () {
        responses[0] =
            Try.reject<FavoriteWinesPage>(UnknownFailure(Exception('off')));
        return buildBloc();
      },
      act: (bloc) => bloc.add(FavoritesListStarted()),
      expect: () => [
        isA<FavoritesListLoading>(),
        isA<FavoritesListError>().having(
            (s) => s.message, 'message', 'favorites_error_connection'),
      ],
    );

    blocTest<FavoritesListBloc, FavoritesListState>(
      '401 -> logout e sessão expirada',
      build: () {
        responses[0] = Try.reject<FavoriteWinesPage>(
          KnownFailure(FavoriteFailureCode.unauthorized, null),
        );
        return buildBloc();
      },
      act: (bloc) => bloc.add(FavoritesListStarted()),
      expect: () => [
        isA<FavoritesListLoading>(),
        isA<FavoritesListSessionExpired>()
            .having((s) => s.message, 'message', 'session_expired'),
      ],
      verify: (_) => verify(() => mockLogout()).called(1),
    );

    blocTest<FavoritesListBloc, FavoritesListState>(
      'esconde vinhos já desfavoritados no cache',
      build: () {
        when(() => mockWatchFavoriteIds.current)
            .thenReturn(const FavoriteIds(ids: {'1'}, isLoaded: true));
        responses[0] =
            _page(_favorites(1, 2), total: 2, hasMore: false);
        return buildBloc();
      },
      act: (bloc) => bloc.add(FavoritesListStarted()),
      expect: () => [
        isA<FavoritesListLoading>(),
        _loaded(ids: ['1'], total: 1),
      ],
    );
  });

  group('FavoritesListLoadMoreRequested', () {
    blocTest<FavoritesListBloc, FavoritesListState>(
      'anexa a próxima página e encerra quando não há mais',
      build: () {
        responses[20] =
            _page(_favorites(21, 5), offset: 20, total: 25, hasMore: false);
        return buildBloc();
      },
      seed: () => _loadedState(
        _favorites(1, 20),
        hasMore: true,
        nextOffset: 20,
        total: 25,
      ),
      act: (bloc) => bloc.add(FavoritesListLoadMoreRequested()),
      expect: () => [
        isA<FavoritesListLoaded>()
            .having((s) => s.isLoadingMore, 'isLoadingMore', isTrue),
        _loaded(ids: _ids(1, 25), hasMore: false, total: 25)
            .having((s) => s.isLoadingMore, 'isLoadingMore', isFalse),
      ],
    );

    blocTest<FavoritesListBloc, FavoritesListState>(
      'erro ao carregar mais mantém os itens e mostra o rodapé de erro',
      build: () {
        responses[20] = Try.reject<FavoriteWinesPage>(
          KnownFailure(FavoriteFailureCode.server, null),
        );
        return buildBloc();
      },
      seed: () => _loadedState(
        _favorites(1, 20),
        hasMore: true,
        nextOffset: 20,
        total: 45,
      ),
      act: (bloc) => bloc.add(FavoritesListLoadMoreRequested()),
      expect: () => [
        isA<FavoritesListLoaded>()
            .having((s) => s.isLoadingMore, 'isLoadingMore', isTrue),
        _loaded(ids: _ids(1, 20)).having((s) => s.loadMoreError,
            'loadMoreError', 'favorites_load_more_error'),
      ],
    );

    blocTest<FavoritesListBloc, FavoritesListState>(
      'ignora quando não há mais páginas',
      build: buildBloc,
      seed: () => _loadedState(_favorites(1, 3)),
      act: (bloc) => bloc.add(FavoritesListLoadMoreRequested()),
      expect: () => const <FavoritesListState>[],
      verify: (_) => verifyNever(() => mockGetFavorites(any())),
    );
  });

  group('FavoritesListRemoveRequested', () {
    blocTest<FavoritesListBloc, FavoritesListState>(
      'remove de forma otimista e ajusta total/offset',
      build: () {
        when(() => mockSetFavorite(any()))
            .thenAnswer((_) async => Try.success(false));
        return buildBloc();
      },
      seed: () => _loadedState(
        _favorites(1, 3),
        hasMore: true,
        nextOffset: 3,
        total: 10,
      ),
      act: (bloc) => bloc.add(FavoritesListRemoveRequested('2')),
      expect: () => [
        _loaded(ids: ['1', '3'], total: 9, nextOffset: 2),
      ],
      verify: (_) {
        final params = verify(() => mockSetFavorite(captureAny()))
            .captured
            .single as SetFavoriteParams;
        expect(params.wineId, '2');
        expect(params.isFavorite, isFalse);
      },
    );

    blocTest<FavoritesListBloc, FavoritesListState>(
      'falha -> devolve o item à mesma posição e sinaliza o erro',
      build: () {
        when(() => mockSetFavorite(any())).thenAnswer((_) async =>
            Try.reject<bool>(UnknownFailure(Exception('offline'))));
        return buildBloc();
      },
      seed: () => _loadedState(_favorites(1, 3)),
      act: (bloc) => bloc.add(FavoritesListRemoveRequested('2')),
      expect: () => [
        _loaded(ids: ['1', '3'], total: 2),
        _loaded(ids: ['1', '2', '3'], total: 3).having(
            (s) => s.actionError, 'actionError', 'favorite_toggle_error'),
      ],
    );

    blocTest<FavoritesListBloc, FavoritesListState>(
      'remover o último favorito -> vazio',
      build: () {
        when(() => mockSetFavorite(any()))
            .thenAnswer((_) async => Try.success(false));
        return buildBloc();
      },
      seed: () => _loadedState([_favorite(1)]),
      act: (bloc) => bloc.add(FavoritesListRemoveRequested('1')),
      expect: () => [isA<FavoritesListEmpty>()],
    );

    blocTest<FavoritesListBloc, FavoritesListState>(
      '401 ao remover -> logout e sessão expirada',
      build: () {
        when(() => mockSetFavorite(any())).thenAnswer((_) async =>
            Try.reject<bool>(
                KnownFailure(FavoriteFailureCode.unauthorized, null)));
        return buildBloc();
      },
      seed: () => _loadedState(_favorites(1, 2)),
      act: (bloc) => bloc.add(FavoritesListRemoveRequested('1')),
      expect: () => [
        _loaded(ids: ['2']),
        isA<FavoritesListSessionExpired>(),
      ],
      verify: (_) => verify(() => mockLogout()).called(1),
    );
  });

  group('sincronização com o cache', () {
    blocTest<FavoritesListBloc, FavoritesListState>(
      'vinho desfavoritado em outra tela sai da lista',
      build: () {
        when(() => mockWatchFavoriteIds.current)
            .thenReturn(const FavoriteIds(ids: {'1', '2'}, isLoaded: true));
        return buildBloc();
      },
      seed: () => _loadedState(_favorites(1, 2)),
      act: (bloc) => favoritesController
          .add(const FavoriteIds(ids: {'1'}, isLoaded: true)),
      wait: const Duration(milliseconds: 10),
      expect: () => [
        _loaded(ids: ['1'], total: 1),
      ],
    );

    blocTest<FavoritesListBloc, FavoritesListState>(
      'vinho favoritado em outra tela recarrega o topo da lista',
      build: () {
        when(() => mockWatchFavoriteIds.current)
            .thenReturn(const FavoriteIds(ids: {'1'}, isLoaded: true));
        responses[0] =
            _page([_favorite(9), _favorite(1)], total: 2, hasMore: false);
        return buildBloc();
      },
      seed: () => _loadedState([_favorite(1)]),
      act: (bloc) {
        when(() => mockWatchFavoriteIds.current).thenReturn(
            const FavoriteIds(ids: {'1', '9'}, isLoaded: true));
        favoritesController
            .add(const FavoriteIds(ids: {'1', '9'}, isLoaded: true));
      },
      wait: const Duration(milliseconds: 10),
      expect: () => [
        isA<FavoritesListLoaded>()
            .having((s) => s.isRefreshing, 'isRefreshing', isTrue),
        _loaded(ids: ['9', '1'], total: 2)
            .having((s) => s.isRefreshing, 'isRefreshing', isFalse),
      ],
    );

    blocTest<FavoritesListBloc, FavoritesListState>(
      'primeira carga dos ids não dispara refresh',
      build: buildBloc,
      seed: () => _loadedState([_favorite(1)]),
      act: (bloc) => favoritesController
          .add(const FavoriteIds(ids: {'1', '9'}, isLoaded: true)),
      wait: const Duration(milliseconds: 10),
      expect: () => const <FavoritesListState>[],
      verify: (_) => verifyNever(() => mockGetFavorites(any())),
    );
  });
}
