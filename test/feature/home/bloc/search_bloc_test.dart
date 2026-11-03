import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:essentials/essentials.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vinum/feature/auth/domain/usecase/logout.dart';
import 'package:vinum/feature/favorites/domain/entity/favorite_failure_code.dart';
import 'package:vinum/feature/favorites/domain/entity/favorite_ids.dart';
import 'package:vinum/feature/favorites/domain/usecase/set_favorite.dart';
import 'package:vinum/feature/favorites/domain/usecase/watch_favorite_ids.dart';
import 'package:vinum/feature/home/domain/entity/food_category.dart';
import 'package:vinum/feature/home/domain/entity/recommendation_failure_code.dart';
import 'package:vinum/feature/home/domain/entity/recommendation_page.dart';
import 'package:vinum/feature/home/domain/entity/recommended_wine.dart';
import 'package:vinum/feature/home/domain/entity/search_result.dart';
import 'package:vinum/feature/home/domain/usecase/search_wines.dart';
import 'package:vinum/feature/home/presentation/bloc/search_bloc.dart';
import 'package:vinum/feature/home/presentation/bloc/search_event.dart';
import 'package:vinum/feature/home/presentation/bloc/search_state.dart';

class MockSearchWines extends Mock implements SearchWines {}

class MockLogout extends Mock implements Logout {}

class MockSetFavorite extends Mock implements SetFavorite {}

class MockWatchFavoriteIds extends Mock implements WatchFavoriteIds {}

RecommendedWine _wine(int id) => RecommendedWine(
      id: '$id',
      name: 'Vinho $id',
      type: 'Red',
      affinityPercentage: 90,
    );

List<RecommendedWine> _wines(int from, int count) =>
    List.generate(count, (i) => _wine(from + i));

Try<SearchResult> _result(
  String query,
  List<RecommendedWine> items, {
  List<FoodCategory> foods = const [],
  int offset = 0,
  int total = 45,
  bool hasMore = true,
}) =>
    Try.success<SearchResult>(SearchResult(
      query: query,
      foods: foods,
      page: RecommendationPage(
        items: items,
        offset: offset,
        total: total,
        hasMore: hasMore,
        nextOffset: hasMore ? offset + items.length : null,
      ),
    ));

/// Debounce curto para os testes; `wait` cobre o timer.
const _debounce = Duration(milliseconds: 20);
const _wait = Duration(milliseconds: 80);

void main() {
  late MockSearchWines mockSearchWines;
  late MockLogout mockLogout;
  late MockSetFavorite mockSetFavorite;
  late MockWatchFavoriteIds mockWatchFavoriteIds;
  late StreamController<FavoriteIds> favoritesController;

  /// Respostas por "query@offset".
  late Map<String, Try<SearchResult>> responses;

  /// Atrasos opcionais por query (para simular respostas fora de ordem).
  late Map<String, Duration> delays;

  setUpAll(() {
    registerFallbackValue(const SearchWinesParams(query: 'x'));
    registerFallbackValue(
      const SetFavoriteParams(wineId: '0', isFavorite: true),
    );
  });

  setUp(() {
    mockSearchWines = MockSearchWines();
    mockLogout = MockLogout();
    mockSetFavorite = MockSetFavorite();
    mockWatchFavoriteIds = MockWatchFavoriteIds();
    favoritesController = StreamController<FavoriteIds>.broadcast();
    responses = {};
    delays = {};
    when(() => mockWatchFavoriteIds())
        .thenAnswer((_) => favoritesController.stream);
    when(() => mockWatchFavoriteIds.current).thenReturn(FavoriteIds.empty);
    when(() => mockLogout()).thenAnswer((_) async => Try.success<void>(null));
    when(() => mockSearchWines(any())).thenAnswer((invocation) async {
      final params =
          invocation.positionalArguments.first as SearchWinesParams;
      final delay = delays[params.query];
      if (delay != null) await Future<void>.delayed(delay);
      return responses['${params.query}@${params.offset}'] ??
          Try.reject<SearchResult>(UnknownFailure('sem stub'));
    });
  });

  tearDown(() => favoritesController.close());

  SearchBloc buildBloc() => SearchBloc(
        mockSearchWines,
        mockLogout,
        mockSetFavorite,
        mockWatchFavoriteIds,
        debounce: _debounce,
      );

  List<SearchWinesParams> capturedParams() =>
      verify(() => mockSearchWines(captureAny()))
          .captured
          .cast<SearchWinesParams>();

  test('estado inicial é SearchIdle', () async {
    final bloc = buildBloc();
    expect(bloc.state, isA<SearchIdle>());
    await bloc.close();
  });

  test('hasMinLetters conta letras (com acentos), não dígitos', () {
    expect(SearchBloc.hasMinLetters('a'), isFalse);
    expect(SearchBloc.hasMinLetters('2015'), isFalse);
    expect(SearchBloc.hasMinLetters('a1'), isFalse);
    expect(SearchBloc.hasMinLetters('rosé'), isTrue);
    expect(SearchBloc.hasMinLetters('çã'), isTrue);
  });

  group('SearchQueryChanged', () {
    blocTest<SearchBloc, SearchState>(
      'faz debounce e busca só o último texto (limit 20, offset 0)',
      build: () {
        responses['picanha@0'] = _result(
          'picanha',
          _wines(1, 20),
          foods: const [FoodCategory.meat],
        );
        return buildBloc();
      },
      act: (bloc) {
        bloc
          ..add(SearchQueryChanged('pic'))
          ..add(SearchQueryChanged('pica'))
          ..add(SearchQueryChanged('picanha '));
      },
      wait: _wait,
      expect: () => [
        isA<SearchLoading>().having((s) => s.query, 'query', 'pic'),
        isA<SearchLoading>().having((s) => s.query, 'query', 'pica'),
        isA<SearchLoading>().having((s) => s.query, 'query', 'picanha'),
        isA<SearchLoaded>()
            .having((s) => s.query, 'query', 'picanha')
            .having((s) => s.items.length, 'items', 20)
            .having((s) => s.foods, 'foods', [FoodCategory.meat])
            .having((s) => s.hasMore, 'hasMore', isTrue)
            .having((s) => s.nextOffset, 'nextOffset', 20)
            .having((s) => s.total, 'total', 45),
      ],
      verify: (_) {
        final params = capturedParams().single;
        expect(params.query, 'picanha');
        expect(params.offset, 0);
        expect(params.limit, SearchBloc.pageSize);
      },
    );

    blocTest<SearchBloc, SearchState>(
      'menos de 2 letras -> SearchQueryTooShort sem chamar a API',
      build: buildBloc,
      act: (bloc) => bloc.add(SearchQueryChanged('a')),
      wait: _wait,
      expect: () => [
        isA<SearchQueryTooShort>().having((s) => s.query, 'query', 'a'),
      ],
      verify: (_) => verifyNever(() => mockSearchWines(any())),
    );

    blocTest<SearchBloc, SearchState>(
      'apagar o texto -> SearchIdle e a busca pendente é cancelada',
      build: buildBloc,
      act: (bloc) {
        bloc
          ..add(SearchQueryChanged('malbec'))
          ..add(SearchQueryChanged('   '));
      },
      wait: _wait,
      expect: () => [isA<SearchLoading>(), isA<SearchIdle>()],
      verify: (_) => verifyNever(() => mockSearchWines(any())),
    );

    blocTest<SearchBloc, SearchState>(
      'ignora resposta obsoleta quando o texto muda durante a busca',
      build: () {
        delays['malbec'] = const Duration(milliseconds: 60);
        responses['malbec@0'] = _result('malbec', _wines(1, 3));
        responses['merlot@0'] =
            _result('merlot', _wines(10, 2), hasMore: false);
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(SearchQueryChanged('malbec'));
        // Debounce termina e a busca de "malbec" fica em voo.
        await Future<void>.delayed(const Duration(milliseconds: 30));
        bloc.add(SearchQueryChanged('merlot'));
      },
      wait: const Duration(milliseconds: 150),
      expect: () => [
        isA<SearchLoading>().having((s) => s.query, 'query', 'malbec'),
        isA<SearchLoading>().having((s) => s.query, 'query', 'merlot'),
        isA<SearchLoaded>()
            .having((s) => s.query, 'query', 'merlot')
            .having((s) => s.items.first.id, 'first id', '10'),
      ],
      verify: (_) {
        expect(capturedParams().map((p) => p.query), ['malbec', 'merlot']);
      },
    );

    blocTest<SearchBloc, SearchState>(
      'com resultados na tela, eles ficam até a nova busca sair',
      build: () {
        responses['malbec@0'] = _result('malbec', _wines(1, 3));
        responses['merlot@0'] = _result('merlot', _wines(10, 2));
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(SearchSubmitted('malbec'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(SearchQueryChanged('merlot'));
      },
      wait: _wait,
      expect: () => [
        isA<SearchLoading>().having((s) => s.query, 'query', 'malbec'),
        isA<SearchLoaded>().having((s) => s.query, 'query', 'malbec'),
        isA<SearchLoading>().having((s) => s.query, 'query', 'merlot'),
        isA<SearchLoaded>().having((s) => s.query, 'query', 'merlot'),
      ],
    );
  });

  group('SearchSubmitted', () {
    blocTest<SearchBloc, SearchState>(
      'busca na hora, sem esperar o debounce',
      build: () {
        responses['sushi@0'] = _result(
          'sushi',
          _wines(1, 2),
          foods: const [FoodCategory.seafood],
          hasMore: false,
        );
        return buildBloc();
      },
      act: (bloc) => bloc.add(SearchSubmitted('sushi')),
      expect: () => [
        isA<SearchLoading>(),
        isA<SearchLoaded>()
            .having((s) => s.hasMore, 'hasMore', isFalse)
            .having((s) => s.foods, 'foods', [FoodCategory.seafood]),
      ],
    );

    blocTest<SearchBloc, SearchState>(
      'sem vinhos -> SearchEmpty mantendo as comidas reconhecidas',
      build: () {
        responses['churrasco@0'] = _result(
          'churrasco',
          const [],
          foods: const [FoodCategory.meat],
          total: 0,
          hasMore: false,
        );
        return buildBloc();
      },
      act: (bloc) => bloc.add(SearchSubmitted('churrasco')),
      expect: () => [
        isA<SearchLoading>(),
        isA<SearchEmpty>()
            .having((s) => s.query, 'query', 'churrasco')
            .having((s) => s.foods, 'foods', [FoodCategory.meat]),
      ],
    );

    blocTest<SearchBloc, SearchState>(
      'erro de conexão -> SearchError e "tentar novamente" refaz a busca',
      build: () {
        responses['malbec@0'] =
            Try.reject<SearchResult>(UnknownFailure(Exception('off')));
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(SearchSubmitted('malbec'));
        await Future<void>.delayed(Duration.zero);
        responses['malbec@0'] = _result('malbec', _wines(1, 2));
        bloc.add(SearchRetried());
      },
      expect: () => [
        isA<SearchLoading>(),
        isA<SearchError>().having(
            (s) => s.message, 'message', 'search_error_connection'),
        isA<SearchLoading>(),
        isA<SearchLoaded>().having((s) => s.items.length, 'items', 2),
      ],
    );

    blocTest<SearchBloc, SearchState>(
      'erro de servidor -> mensagem de servidor',
      build: () {
        responses['malbec@0'] = Try.reject<SearchResult>(
          KnownFailure(RecommendationFailureCode.server, null),
        );
        return buildBloc();
      },
      act: (bloc) => bloc.add(SearchSubmitted('malbec')),
      expect: () => [
        isA<SearchLoading>(),
        isA<SearchError>()
            .having((s) => s.message, 'message', 'search_error_server'),
      ],
    );

    blocTest<SearchBloc, SearchState>(
      '400 -> SearchQueryTooShort',
      build: () {
        responses['ab@0'] = Try.reject<SearchResult>(
          KnownFailure(RecommendationFailureCode.badRequest, null),
        );
        return buildBloc();
      },
      act: (bloc) => bloc.add(SearchSubmitted('ab')),
      expect: () => [isA<SearchLoading>(), isA<SearchQueryTooShort>()],
    );

    blocTest<SearchBloc, SearchState>(
      '409 ONBOARDING_REQUIRED -> SearchOnboardingRequired',
      build: () {
        responses['malbec@0'] = Try.reject<SearchResult>(
          KnownFailure(RecommendationFailureCode.onboardingRequired, null),
        );
        return buildBloc();
      },
      act: (bloc) => bloc.add(SearchSubmitted('malbec')),
      expect: () => [
        isA<SearchLoading>(),
        isA<SearchOnboardingRequired>(),
      ],
    );

    blocTest<SearchBloc, SearchState>(
      '401 -> logout e SearchSessionExpired',
      build: () {
        responses['malbec@0'] = Try.reject<SearchResult>(
          KnownFailure(RecommendationFailureCode.unauthorized, null),
        );
        return buildBloc();
      },
      act: (bloc) => bloc.add(SearchSubmitted('malbec')),
      expect: () => [
        isA<SearchLoading>(),
        isA<SearchSessionExpired>()
            .having((s) => s.message, 'message', 'session_expired'),
      ],
      verify: (_) => verify(() => mockLogout()).called(1),
    );
  });

  group('SearchLoadMoreRequested', () {
    blocTest<SearchBloc, SearchState>(
      'carrega a próxima página pelo next_offset e concatena',
      build: () {
        responses['malbec@0'] = _result('malbec', _wines(1, 20));
        responses['malbec@20'] =
            _result('malbec', _wines(21, 5), offset: 20, hasMore: false);
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(SearchSubmitted('malbec'));
        await Future<void>.delayed(Duration.zero);
        bloc
          ..add(SearchLoadMoreRequested())
          ..add(SearchLoadMoreRequested());
      },
      skip: 2,
      expect: () => [
        isA<SearchLoaded>()
            .having((s) => s.isLoadingMore, 'isLoadingMore', isTrue),
        isA<SearchLoaded>()
            .having((s) => s.items.length, 'items', 25)
            .having((s) => s.hasMore, 'hasMore', isFalse)
            .having((s) => s.isLoadingMore, 'isLoadingMore', isFalse),
      ],
      verify: (_) {
        expect(capturedParams().map((p) => p.offset), [0, 20]);
      },
    );

    blocTest<SearchBloc, SearchState>(
      'falha ao carregar mais mantém os itens e sinaliza o erro',
      build: () {
        responses['malbec@0'] = _result('malbec', _wines(1, 20));
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(SearchSubmitted('malbec'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(SearchLoadMoreRequested());
      },
      skip: 3,
      expect: () => [
        isA<SearchLoaded>()
            .having((s) => s.items.length, 'items', 20)
            .having((s) => s.loadMoreError, 'error', 'search_load_more_error'),
      ],
    );
  });

  group('favoritos', () {
    blocTest<SearchBloc, SearchState>(
      'favorita de forma otimista; falha volta e sinaliza o erro',
      build: () {
        responses['malbec@0'] = _result('malbec', _wines(1, 2));
        when(() => mockSetFavorite(any())).thenAnswer(
          (_) async => Try.reject<bool>(
            KnownFailure(FavoriteFailureCode.server, null),
          ),
        );
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(SearchSubmitted('malbec'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(SearchFavoriteToggled('1'));
      },
      skip: 2,
      expect: () => [
        isA<SearchLoaded>()
            .having((s) => s.items.first.isFavorite, 'isFavorite', isTrue),
        isA<SearchLoaded>()
            .having((s) => s.items.first.isFavorite, 'isFavorite', isFalse)
            .having((s) => s.favoriteErrorMessage, 'error',
                'favorite_toggle_error'),
      ],
    );

    blocTest<SearchBloc, SearchState>(
      'reflete mudanças do cache de favoritos feitas em outras telas',
      build: () {
        responses['malbec@0'] = _result('malbec', _wines(1, 2));
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(SearchSubmitted('malbec'));
        await Future<void>.delayed(Duration.zero);
        favoritesController
            .add(const FavoriteIds(ids: {'2'}, isLoaded: true));
      },
      wait: const Duration(milliseconds: 10),
      skip: 2,
      expect: () => [
        isA<SearchLoaded>()
            .having((s) => s.items[0].isFavorite, 'first', isFalse)
            .having((s) => s.items[1].isFavorite, 'second', isTrue),
      ],
    );
  });
}
