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
import 'package:vinum/feature/home/domain/usecase/get_food_recommendations.dart';
import 'package:vinum/feature/home/presentation/bloc/food_wines_bloc.dart';
import 'package:vinum/feature/home/presentation/bloc/food_wines_event.dart';
import 'package:vinum/feature/home/presentation/bloc/food_wines_state.dart';

class MockGetFoodRecommendations extends Mock
    implements GetFoodRecommendations {}

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

Try<RecommendationPage> _page(
  List<RecommendedWine> items, {
  int offset = 0,
  int total = 45,
  bool hasMore = true,
  int? nextOffset,
}) =>
    Try.success<RecommendationPage>(RecommendationPage(
      items: items,
      offset: offset,
      total: total,
      hasMore: hasMore,
      nextOffset: hasMore ? (nextOffset ?? offset + items.length) : null,
    ));

TypeMatcher<FoodWinesLoaded> _loaded({
  int? count,
  bool? hasMore,
  bool? isLoadingMore,
  bool? isRefreshing,
  Object? loadMoreError = _skip,
}) {
  var matcher = isA<FoodWinesLoaded>();
  if (count != null) {
    matcher = matcher.having((s) => s.items.length, 'items.length', count);
  }
  if (hasMore != null) {
    matcher = matcher.having((s) => s.hasMore, 'hasMore', hasMore);
  }
  if (isLoadingMore != null) {
    matcher =
        matcher.having((s) => s.isLoadingMore, 'isLoadingMore', isLoadingMore);
  }
  if (isRefreshing != null) {
    matcher =
        matcher.having((s) => s.isRefreshing, 'isRefreshing', isRefreshing);
  }
  if (!identical(loadMoreError, _skip)) {
    matcher =
        matcher.having((s) => s.loadMoreError, 'loadMoreError', loadMoreError);
  }
  return matcher;
}

const Object _skip = Object();

void main() {
  late MockGetFoodRecommendations mockGetFoodRecommendations;
  late MockLogout mockLogout;
  late MockSetFavorite mockSetFavorite;
  late MockWatchFavoriteIds mockWatchFavoriteIds;
  late StreamController<FavoriteIds> favoritesController;

  /// Respostas por offset pedido.
  late Map<int, Try<RecommendationPage>> responses;

  setUpAll(() {
    registerFallbackValue(
      const GetFoodRecommendationsParams(food: FoodCategory.meat),
    );
    registerFallbackValue(
      const SetFavoriteParams(wineId: '0', isFavorite: true),
    );
  });

  setUp(() {
    mockGetFoodRecommendations = MockGetFoodRecommendations();
    mockLogout = MockLogout();
    mockSetFavorite = MockSetFavorite();
    mockWatchFavoriteIds = MockWatchFavoriteIds();
    favoritesController = StreamController<FavoriteIds>.broadcast();
    responses = {};
    when(() => mockWatchFavoriteIds())
        .thenAnswer((_) => favoritesController.stream);
    when(() => mockWatchFavoriteIds.current).thenReturn(FavoriteIds.empty);
    when(() => mockLogout()).thenAnswer((_) async => Try.success<void>(null));
    when(() => mockGetFoodRecommendations(any())).thenAnswer((invocation) async {
      final params =
          invocation.positionalArguments.first as GetFoodRecommendationsParams;
      return responses[params.offset] ??
          Try.reject<RecommendationPage>(UnknownFailure('sem stub'));
    });
  });

  tearDown(() => favoritesController.close());

  FoodWinesBloc buildBloc() => FoodWinesBloc(
        mockGetFoodRecommendations,
        mockLogout,
        mockSetFavorite,
        mockWatchFavoriteIds,
      );

  List<GetFoodRecommendationsParams> capturedParams() =>
      verify(() => mockGetFoodRecommendations(captureAny()))
          .captured
          .cast<GetFoodRecommendationsParams>();

  group('FoodWinesStarted', () {
    blocTest<FoodWinesBloc, FoodWinesState>(
      'carrega a primeira página (offset 0, limit 20, food)',
      build: () {
        responses[0] = _page(_wines(1, 20));
        return buildBloc();
      },
      act: (bloc) => bloc.add(FoodWinesStarted(FoodCategory.meat)),
      expect: () => [
        isA<FoodWinesLoading>(),
        _loaded(count: 20, hasMore: true, isLoadingMore: false)
            .having((s) => s.nextOffset, 'nextOffset', 20)
            .having((s) => s.total, 'total', 45),
      ],
      verify: (_) {
        final params = capturedParams().single;
        expect(params.offset, 0);
        expect(params.limit, FoodWinesBloc.pageSize);
        expect(params.limit, 20);
        expect(params.food, FoodCategory.meat);
      },
    );

    blocTest<FoodWinesBloc, FoodWinesState>(
      'lista vazia -> FoodWinesEmpty',
      build: () {
        responses[0] = _page(const [], total: 0, hasMore: false);
        return buildBloc();
      },
      act: (bloc) => bloc.add(FoodWinesStarted(FoodCategory.dessert)),
      expect: () => [isA<FoodWinesLoading>(), isA<FoodWinesEmpty>()],
    );

    blocTest<FoodWinesBloc, FoodWinesState>(
      'erro de servidor -> FoodWinesError com chave i18n',
      build: () {
        responses[0] = Try.reject<RecommendationPage>(
          KnownFailure(RecommendationFailureCode.server, null),
        );
        return buildBloc();
      },
      act: (bloc) => bloc.add(FoodWinesStarted(FoodCategory.meat)),
      expect: () => [
        isA<FoodWinesLoading>(),
        isA<FoodWinesError>()
            .having((s) => s.message, 'message', 'food_wines_error_server'),
      ],
    );

    blocTest<FoodWinesBloc, FoodWinesState>(
      '400 -> categoria inválida',
      build: () {
        responses[0] = Try.reject<RecommendationPage>(
          KnownFailure(RecommendationFailureCode.badRequest, null),
        );
        return buildBloc();
      },
      act: (bloc) => bloc.add(FoodWinesStarted(FoodCategory.meat)),
      expect: () => [
        isA<FoodWinesLoading>(),
        isA<FoodWinesError>().having(
            (s) => s.message, 'message', 'food_wines_error_invalid_category'),
      ],
    );

    blocTest<FoodWinesBloc, FoodWinesState>(
      'sem conexão (UnknownFailure) -> mensagem de conexão',
      build: () {
        responses[0] =
            Try.reject<RecommendationPage>(UnknownFailure(Exception('off')));
        return buildBloc();
      },
      act: (bloc) => bloc.add(FoodWinesStarted(FoodCategory.meat)),
      expect: () => [
        isA<FoodWinesLoading>(),
        isA<FoodWinesError>().having(
            (s) => s.message, 'message', 'food_wines_error_connection'),
      ],
    );

    blocTest<FoodWinesBloc, FoodWinesState>(
      '409 ONBOARDING_REQUIRED -> FoodWinesOnboardingRequired',
      build: () {
        responses[0] = Try.reject<RecommendationPage>(
          KnownFailure(RecommendationFailureCode.onboardingRequired, null),
        );
        return buildBloc();
      },
      act: (bloc) => bloc.add(FoodWinesStarted(FoodCategory.meat)),
      expect: () => [
        isA<FoodWinesLoading>(),
        isA<FoodWinesOnboardingRequired>(),
      ],
    );

    blocTest<FoodWinesBloc, FoodWinesState>(
      '401 -> logout e FoodWinesSessionExpired',
      build: () {
        responses[0] = Try.reject<RecommendationPage>(
          KnownFailure(RecommendationFailureCode.unauthorized, null),
        );
        return buildBloc();
      },
      act: (bloc) => bloc.add(FoodWinesStarted(FoodCategory.meat)),
      expect: () => [
        isA<FoodWinesLoading>(),
        isA<FoodWinesSessionExpired>()
            .having((s) => s.message, 'message', 'session_expired'),
      ],
      verify: (_) => verify(() => mockLogout()).called(1),
    );
  });

  group('FoodWinesLoadMoreRequested', () {
    blocTest<FoodWinesBloc, FoodWinesState>(
      'carrega a próxima página e concatena',
      build: () {
        responses[0] = _page(_wines(1, 20));
        responses[20] = _page(_wines(21, 20), offset: 20);
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(FoodWinesStarted(FoodCategory.meat));
        await Future<void>.delayed(Duration.zero);
        bloc.add(FoodWinesLoadMoreRequested());
      },
      expect: () => [
        isA<FoodWinesLoading>(),
        _loaded(count: 20, isLoadingMore: false),
        _loaded(count: 20, isLoadingMore: true),
        _loaded(count: 40, isLoadingMore: false, hasMore: true)
            .having((s) => s.nextOffset, 'nextOffset', 40)
            .having((s) => s.items.last.id, 'last id', '40'),
      ],
      verify: (_) {
        expect(capturedParams().map((p) => p.offset), [0, 20]);
      },
    );

    blocTest<FoodWinesBloc, FoodWinesState>(
      'não dispara em paralelo enquanto já está carregando',
      build: () {
        responses[0] = _page(_wines(1, 20));
        responses[20] = _page(_wines(21, 20), offset: 20);
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(FoodWinesStarted(FoodCategory.meat));
        await Future<void>.delayed(Duration.zero);
        // Dois gatilhos seguidos do scroll: só o primeiro busca.
        bloc
          ..add(FoodWinesLoadMoreRequested())
          ..add(FoodWinesLoadMoreRequested());
      },
      skip: 2, // Loading + primeira página
      expect: () => [
        _loaded(count: 20, isLoadingMore: true),
        _loaded(count: 40, isLoadingMore: false),
      ],
      verify: (_) {
        expect(capturedParams().map((p) => p.offset), [0, 20]);
      },
    );

    blocTest<FoodWinesBloc, FoodWinesState>(
      'fim da lista: has_more false encerra e novos pedidos são ignorados',
      build: () {
        responses[0] = _page(_wines(1, 20));
        responses[20] = _page(_wines(21, 5), offset: 20, hasMore: false);
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(FoodWinesStarted(FoodCategory.meat));
        await Future<void>.delayed(Duration.zero);
        bloc.add(FoodWinesLoadMoreRequested());
        await Future<void>.delayed(Duration.zero);
        bloc.add(FoodWinesLoadMoreRequested());
      },
      expect: () => [
        isA<FoodWinesLoading>(),
        _loaded(count: 20, hasMore: true),
        _loaded(count: 20, isLoadingMore: true),
        _loaded(count: 25, hasMore: false, isLoadingMore: false),
      ],
      verify: (_) {
        expect(capturedParams().map((p) => p.offset), [0, 20]);
      },
    );

    blocTest<FoodWinesBloc, FoodWinesState>(
      'erro ao carregar mais preserva os itens e permite tentar novamente',
      build: () {
        responses[0] = _page(_wines(1, 20));
        responses[20] =
            Try.reject<RecommendationPage>(UnknownFailure(Exception('off')));
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(FoodWinesStarted(FoodCategory.meat));
        await Future<void>.delayed(Duration.zero);
        bloc.add(FoodWinesLoadMoreRequested());
        await Future<void>.delayed(Duration.zero);
        // "Tentar novamente" no rodapé, agora com sucesso.
        responses[20] = _page(_wines(21, 20), offset: 20);
        bloc.add(FoodWinesLoadMoreRequested());
      },
      expect: () => [
        isA<FoodWinesLoading>(),
        _loaded(count: 20, loadMoreError: null),
        _loaded(count: 20, isLoadingMore: true, loadMoreError: null),
        _loaded(
          count: 20,
          isLoadingMore: false,
          hasMore: true,
          loadMoreError: 'food_wines_load_more_error',
        ).having((s) => s.items.first.id, 'first id', '1'),
        _loaded(count: 20, isLoadingMore: true, loadMoreError: null),
        _loaded(count: 40, isLoadingMore: false, loadMoreError: null),
      ],
    );

    blocTest<FoodWinesBloc, FoodWinesState>(
      'deduplica por wine_id entre páginas',
      build: () {
        responses[0] = _page(_wines(1, 20));
        // Página 2 repete os ids 19 e 20.
        responses[20] = _page(_wines(19, 20), offset: 20);
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(FoodWinesStarted(FoodCategory.meat));
        await Future<void>.delayed(Duration.zero);
        bloc.add(FoodWinesLoadMoreRequested());
      },
      skip: 3,
      expect: () => [
        _loaded(count: 38).having(
          (s) => s.items.map((w) => w.id).toSet().length,
          'ids únicos',
          38,
        ),
      ],
    );

    blocTest<FoodWinesBloc, FoodWinesState>(
      '401 ao carregar mais -> logout e sessão expirada',
      build: () {
        responses[0] = _page(_wines(1, 20));
        responses[20] = Try.reject<RecommendationPage>(
          KnownFailure(RecommendationFailureCode.unauthorized, null),
        );
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(FoodWinesStarted(FoodCategory.meat));
        await Future<void>.delayed(Duration.zero);
        bloc.add(FoodWinesLoadMoreRequested());
      },
      skip: 3,
      expect: () => [isA<FoodWinesSessionExpired>()],
      verify: (_) => verify(() => mockLogout()).called(1),
    );
  });

  group('FoodWinesRefreshed', () {
    blocTest<FoodWinesBloc, FoodWinesState>(
      'recarrega do offset 0 substituindo a lista',
      build: () {
        responses[0] = _page(_wines(1, 20));
        responses[20] = _page(_wines(21, 20), offset: 20);
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(FoodWinesStarted(FoodCategory.meat));
        await Future<void>.delayed(Duration.zero);
        bloc.add(FoodWinesLoadMoreRequested());
        await Future<void>.delayed(Duration.zero);
        responses[0] = _page(_wines(100, 20));
        bloc.add(FoodWinesRefreshed());
      },
      skip: 4, // Loading, página 1, carregando mais, 40 itens
      expect: () => [
        _loaded(count: 40, isRefreshing: true),
        _loaded(count: 20, isRefreshing: false, hasMore: true)
            .having((s) => s.items.first.id, 'first id', '100')
            .having((s) => s.nextOffset, 'nextOffset', 20),
      ],
      verify: (_) {
        expect(capturedParams().map((p) => p.offset), [0, 20, 0]);
      },
    );

    blocTest<FoodWinesBloc, FoodWinesState>(
      'erro no refresh mantém os itens e expõe refreshError',
      build: () {
        responses[0] = _page(_wines(1, 20));
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(FoodWinesStarted(FoodCategory.meat));
        await Future<void>.delayed(Duration.zero);
        responses[0] = Try.reject<RecommendationPage>(
          KnownFailure(RecommendationFailureCode.server, null),
        );
        bloc.add(FoodWinesRefreshed());
      },
      skip: 2,
      expect: () => [
        _loaded(count: 20, isRefreshing: true),
        _loaded(count: 20, isRefreshing: false).having(
            (s) => s.refreshError, 'refreshError', 'food_wines_error_server'),
      ],
    );

    blocTest<FoodWinesBloc, FoodWinesState>(
      'refresh no estado de erro recarrega do zero',
      build: () {
        responses[0] =
            Try.reject<RecommendationPage>(UnknownFailure(Exception('off')));
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(FoodWinesStarted(FoodCategory.meat));
        await Future<void>.delayed(Duration.zero);
        responses[0] = _page(_wines(1, 3), hasMore: false);
        bloc.add(FoodWinesRefreshed());
      },
      expect: () => [
        isA<FoodWinesLoading>(),
        isA<FoodWinesError>(),
        isA<FoodWinesLoading>(),
        _loaded(count: 3, hasMore: false),
      ],
    );
  });

  group('favoritos', () {
    blocTest<FoodWinesBloc, FoodWinesState>(
      'aplica o cache sobre is_favorite da primeira página',
      build: () {
        when(() => mockWatchFavoriteIds.current).thenReturn(
          const FavoriteIds(ids: {'2'}, isLoaded: true),
        );
        responses[0] = _page(
          [_wine(1).copyWith(isFavorite: true), _wine(2)],
          hasMore: false,
        );
        return buildBloc();
      },
      act: (bloc) => bloc.add(FoodWinesStarted(FoodCategory.meat)),
      expect: () => [
        isA<FoodWinesLoading>(),
        _loaded(count: 2)
            .having((s) => s.items[0].isFavorite, 'item 1', isFalse)
            .having((s) => s.items[1].isFavorite, 'item 2', isTrue),
      ],
    );

    blocTest<FoodWinesBloc, FoodWinesState>(
      'toggle otimista com sucesso',
      build: () {
        when(() => mockSetFavorite(any()))
            .thenAnswer((_) async => Try.success(true));
        return buildBloc();
      },
      seed: () => FoodWinesLoaded(
        items: [_wine(1)],
        hasMore: false,
        nextOffset: 1,
        total: 1,
      ),
      act: (bloc) => bloc.add(FoodWinesFavoriteToggled('1')),
      expect: () => [
        _loaded(count: 1)
            .having((s) => s.items.single.isFavorite, 'isFavorite', isTrue),
      ],
    );

    blocTest<FoodWinesBloc, FoodWinesState>(
      'toggle com falha volta o estado e sinaliza o erro',
      build: () {
        when(() => mockSetFavorite(any())).thenAnswer((_) async =>
            Try.reject<bool>(UnknownFailure(Exception('offline'))));
        return buildBloc();
      },
      seed: () => FoodWinesLoaded(
        items: [_wine(1)],
        hasMore: false,
        nextOffset: 1,
        total: 1,
      ),
      act: (bloc) => bloc.add(FoodWinesFavoriteToggled('1')),
      expect: () => [
        _loaded(count: 1)
            .having((s) => s.items.single.isFavorite, 'isFavorite', isTrue),
        _loaded(count: 1)
            .having((s) => s.items.single.isFavorite, 'isFavorite', isFalse)
            .having((s) => s.favoriteErrorMessage, 'error',
                'favorite_toggle_error'),
      ],
    );

    blocTest<FoodWinesBloc, FoodWinesState>(
      'toggle com 401 faz logout e expira a sessão',
      build: () {
        when(() => mockSetFavorite(any())).thenAnswer((_) async =>
            Try.reject<bool>(
                KnownFailure(FavoriteFailureCode.unauthorized, null)));
        return buildBloc();
      },
      seed: () => FoodWinesLoaded(
        items: [_wine(1)],
        hasMore: false,
        nextOffset: 1,
        total: 1,
      ),
      act: (bloc) => bloc.add(FoodWinesFavoriteToggled('1')),
      expect: () => [
        _loaded(count: 1),
        isA<FoodWinesSessionExpired>(),
      ],
      verify: (_) => verify(() => mockLogout()).called(1),
    );

    blocTest<FoodWinesBloc, FoodWinesState>(
      'mudança do cache em outra tela atualiza o item',
      build: buildBloc,
      seed: () => FoodWinesLoaded(
        items: [_wine(1), _wine(2)],
        hasMore: false,
        nextOffset: 2,
        total: 2,
      ),
      act: (bloc) => favoritesController
          .add(const FavoriteIds(ids: {'2'}, removed: {'1'})),
      wait: const Duration(milliseconds: 10),
      expect: () => [
        _loaded(count: 2)
            .having((s) => s.items[0].isFavorite, 'item 1', isFalse)
            .having((s) => s.items[1].isFavorite, 'item 2', isTrue),
      ],
    );
  });
}
