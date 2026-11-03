import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:essentials/essentials.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vinum/feature/auth/domain/entity/user.dart';
import 'package:vinum/feature/auth/domain/repository/auth_repository.dart';
import 'package:vinum/feature/auth/domain/usecase/logout.dart';
import 'package:vinum/feature/favorites/domain/entity/favorite_failure_code.dart';
import 'package:vinum/feature/favorites/domain/entity/favorite_ids.dart';
import 'package:vinum/feature/favorites/domain/usecase/load_favorite_ids.dart';
import 'package:vinum/feature/favorites/domain/usecase/set_favorite.dart';
import 'package:vinum/feature/favorites/domain/usecase/watch_favorite_ids.dart';
import 'package:vinum/feature/home/domain/entity/highlight_wine.dart';
import 'package:vinum/feature/home/domain/entity/recommendation_failure_code.dart';
import 'package:vinum/feature/home/domain/entity/recommended_wine.dart';
import 'package:vinum/feature/home/domain/usecase/get_recommendations.dart';
import 'package:vinum/feature/home/presentation/bloc/home_bloc.dart';
import 'package:vinum/feature/home/presentation/bloc/home_event.dart';
import 'package:vinum/feature/home/presentation/bloc/home_state.dart';
import 'package:vinum/feature/wine/domain/entity/wine.dart';
import 'package:vinum/feature/wine/domain/entity/wine_failure_code.dart';
import 'package:vinum/feature/wine/domain/entity/wine_highlights.dart';
import 'package:vinum/feature/wine/domain/usecase/get_wine_highlights.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockGetRecommendations extends Mock implements GetRecommendations {}

class MockLogout extends Mock implements Logout {}

class MockLoadFavoriteIds extends Mock implements LoadFavoriteIds {}

class MockSetFavorite extends Mock implements SetFavorite {}

class MockWatchFavoriteIds extends Mock implements WatchFavoriteIds {}

class MockGetWineHighlights extends Mock implements GetWineHighlights {}

const _tUser = User(id: '1', email: 'test@example.com', name: 'Test User');

const _tWine = RecommendedWine(
  id: '100003',
  name: 'Cabernet Sauvignon',
  type: 'Red',
  country: 'Brazil',
  region: 'Serra Gaúcha',
  rating: 8.5,
  ratingCount: 2,
  affinityPercentage: 93,
);

const _tHighlight = Wine(
  id: '200',
  name: 'Catena Malbec',
  winery: 'Catena',
  region: 'Mendoza',
  country: 'Argentina',
  grape: 'Malbec',
  vintage: 2020,
  rating: 9.1,
  ratingCount: 12,
  imageUrl: '',
  description: '',
  type: 'Red',
);

const _tHighlightNoRating = Wine(
  id: '201',
  name: 'Novo Branco',
  winery: '',
  region: '',
  country: '',
  grape: '',
  vintage: 0,
  rating: 0,
  imageUrl: '',
  description: '',
);

TypeMatcher<HomeLoaded> _loadedWith(RecommendationsStatus status) =>
    isA<HomeLoaded>().having(
      (s) => s.recommendationsStatus,
      'recommendationsStatus',
      status,
    );

void main() {
  late MockAuthRepository mockAuthRepository;
  late MockGetRecommendations mockGetRecommendations;
  late MockLogout mockLogout;
  late MockLoadFavoriteIds mockLoadFavoriteIds;
  late MockSetFavorite mockSetFavorite;
  late MockWatchFavoriteIds mockWatchFavoriteIds;
  late MockGetWineHighlights mockGetWineHighlights;

  setUpAll(() {
    registerFallbackValue(const GetRecommendationsParams());
    registerFallbackValue(const GetWineHighlightsParams());
    registerFallbackValue(
      const SetFavoriteParams(wineId: '0', isFavorite: true),
    );
  });

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    mockGetRecommendations = MockGetRecommendations();
    mockLogout = MockLogout();
    mockLoadFavoriteIds = MockLoadFavoriteIds();
    mockSetFavorite = MockSetFavorite();
    mockWatchFavoriteIds = MockWatchFavoriteIds();
    mockGetWineHighlights = MockGetWineHighlights();
    when(() => mockAuthRepository.getCurrentUser()).thenReturn(_tUser);
    when(() => mockGetWineHighlights(any())).thenAnswer(
      (_) async => Try.success(
        const WineHighlights(week: '2026-W40', wines: [_tHighlight]),
      ),
    );
    when(() => mockLogout()).thenAnswer((_) async => Try.success<void>(null));
    when(() => mockLoadFavoriteIds())
        .thenAnswer((_) async => Try.success(FavoriteIds.empty));
    when(() => mockWatchFavoriteIds()).thenAnswer((_) => const Stream.empty());
    when(() => mockWatchFavoriteIds.current).thenReturn(FavoriteIds.empty);
  });

  HomeBloc buildBloc() => HomeBloc(
        mockAuthRepository,
        mockGetRecommendations,
        mockLogout,
        mockLoadFavoriteIds,
        mockSetFavorite,
        mockWatchFavoriteIds,
        mockGetWineHighlights,
      );

  void stubSetFavorite(Try<bool> result) {
    when(() => mockSetFavorite(any())).thenAnswer((_) async => result);
  }

  void stubRecommendations(Try<List<RecommendedWine>> result) {
    when(() => mockGetRecommendations(any())).thenAnswer((_) async => result);
  }

  group('HomeStarted', () {
    blocTest<HomeBloc, HomeState>(
      'carrega a home, as recomendações reais (limit 10) e os destaques',
      build: () {
        stubRecommendations(Try.success<List<RecommendedWine>>([_tWine]));
        return buildBloc();
      },
      act: (bloc) => bloc.add(HomeStarted()),
      expect: () => [
        _loadedWith(RecommendationsStatus.loading)
            .having((s) => s.currentUser, 'currentUser', _tUser)
            .having((s) => s.highlightsStatus, 'highlightsStatus',
                HighlightsStatus.loading)
            .having((s) => s.highlights, 'highlights', isEmpty),
        _loadedWith(RecommendationsStatus.loaded)
            .having((s) => s.recommendations.single.id, 'id', '100003')
            .having((s) => s.highlightsStatus, 'highlightsStatus',
                HighlightsStatus.loaded)
            .having((s) => s.highlights.single.id, 'highlight id', '200'),
      ],
      verify: (_) {
        final params = verify(() => mockGetRecommendations(captureAny()))
            .captured
            .single as GetRecommendationsParams;
        expect(params.limit, HomeBloc.recommendationsLimit);
        final highlightParams =
            verify(() => mockGetWineHighlights(captureAny())).captured.single
                as GetWineHighlightsParams;
        expect(highlightParams.limit, HomeBloc.highlightsLimit);
      },
    );

    blocTest<HomeBloc, HomeState>(
      'mapeia os destaques reais (nota só com avaliações, favorito do cache)',
      build: () {
        when(() => mockWatchFavoriteIds.current).thenReturn(
          const FavoriteIds(ids: {'200'}, isLoaded: true),
        );
        when(() => mockGetWineHighlights(any())).thenAnswer(
          (_) async => Try.success(const WineHighlights(
            week: '2026-W40',
            wines: [_tHighlight, _tHighlightNoRating],
          )),
        );
        stubRecommendations(Try.success<List<RecommendedWine>>([_tWine]));
        return buildBloc();
      },
      act: (bloc) => bloc.add(HomeStarted()),
      skip: 1,
      expect: () => [
        _loadedWith(RecommendationsStatus.loaded)
            .having((s) => s.highlights.length, 'length', 2)
            .having((s) => s.highlights[0].name, 'name', 'Catena Malbec')
            .having((s) => s.highlights[0].type, 'type', 'Red')
            .having((s) => s.highlights[0].rating, 'rating', 9.1)
            .having((s) => s.highlights[0].isFavorite, 'fav', isTrue)
            .having((s) => s.highlights[1].rating, 'rating', isNull)
            .having((s) => s.highlights[1].type, 'type', isNull)
            .having((s) => s.highlights[1].isFavorite, 'fav', isFalse),
      ],
    );

    blocTest<HomeBloc, HomeState>(
      'falha nos destaques só oculta a seção',
      build: () {
        when(() => mockGetWineHighlights(any())).thenAnswer(
          (_) async => Try.reject<WineHighlights>(
            KnownFailure(WineFailureCode.server, null),
          ),
        );
        stubRecommendations(Try.success<List<RecommendedWine>>([_tWine]));
        return buildBloc();
      },
      act: (bloc) => bloc.add(HomeStarted()),
      expect: () => [
        _loadedWith(RecommendationsStatus.loading),
        _loadedWith(RecommendationsStatus.loaded)
            .having((s) => s.highlightsStatus, 'highlightsStatus',
                HighlightsStatus.unavailable)
            .having((s) => s.highlights, 'highlights', isEmpty),
      ],
    );

    blocTest<HomeBloc, HomeState>(
      'destaques carregam mesmo com erro nas recomendações',
      build: () {
        stubRecommendations(Try.reject<List<RecommendedWine>>(
          UnknownFailure(Exception('offline')),
        ));
        return buildBloc();
      },
      act: (bloc) => bloc.add(HomeStarted()),
      skip: 1,
      expect: () => [
        _loadedWith(RecommendationsStatus.error)
            .having((s) => s.highlightsStatus, 'highlightsStatus',
                HighlightsStatus.loaded)
            .having((s) => s.highlights, 'highlights', hasLength(1)),
      ],
    );

    blocTest<HomeBloc, HomeState>(
      'lista vazia -> status empty',
      build: () {
        stubRecommendations(Try.success<List<RecommendedWine>>(const []));
        return buildBloc();
      },
      act: (bloc) => bloc.add(HomeStarted()),
      expect: () => [
        _loadedWith(RecommendationsStatus.loading),
        _loadedWith(RecommendationsStatus.empty),
      ],
    );

    blocTest<HomeBloc, HomeState>(
      '409 ONBOARDING_REQUIRED -> status onboardingRequired',
      build: () {
        stubRecommendations(Try.reject<List<RecommendedWine>>(KnownFailure(
          RecommendationFailureCode.onboardingRequired,
          null,
        )));
        return buildBloc();
      },
      act: (bloc) => bloc.add(HomeStarted()),
      expect: () => [
        _loadedWith(RecommendationsStatus.loading),
        _loadedWith(RecommendationsStatus.onboardingRequired)
            .having((s) => s.recommendationsErrorMessage, 'error', isNull),
      ],
    );

    blocTest<HomeBloc, HomeState>(
      'erro de servidor -> status error sem derrubar a home',
      build: () {
        stubRecommendations(Try.reject<List<RecommendedWine>>(
          KnownFailure(RecommendationFailureCode.server, null),
        ));
        return buildBloc();
      },
      act: (bloc) => bloc.add(HomeStarted()),
      expect: () => [
        _loadedWith(RecommendationsStatus.loading),
        _loadedWith(RecommendationsStatus.error)
            .having((s) => s.recommendationsErrorMessage, 'error',
                'home_recommendations_error_server')
            .having((s) => s.highlights, 'highlights', isNotEmpty),
      ],
    );

    blocTest<HomeBloc, HomeState>(
      'falha de conexão (UnknownFailure) -> mensagem de conexão',
      build: () {
        stubRecommendations(Try.reject<List<RecommendedWine>>(
          UnknownFailure(Exception('offline')),
        ));
        return buildBloc();
      },
      act: (bloc) => bloc.add(HomeStarted()),
      expect: () => [
        _loadedWith(RecommendationsStatus.loading),
        _loadedWith(RecommendationsStatus.error).having(
            (s) => s.recommendationsErrorMessage,
            'error',
            'home_recommendations_error_connection'),
      ],
    );

    blocTest<HomeBloc, HomeState>(
      '401 -> logout e HomeSessionExpired',
      build: () {
        stubRecommendations(Try.reject<List<RecommendedWine>>(
          KnownFailure(RecommendationFailureCode.unauthorized, null),
        ));
        return buildBloc();
      },
      act: (bloc) => bloc.add(HomeStarted()),
      expect: () => [
        _loadedWith(RecommendationsStatus.loading),
        isA<HomeSessionExpired>()
            .having((s) => s.message, 'message', 'session_expired'),
      ],
      verify: (_) => verify(() => mockLogout()).called(1),
    );

    blocTest<HomeBloc, HomeState>(
      'carrega os ids favoritos quando o cache ainda não foi carregado',
      build: () {
        stubRecommendations(Try.success<List<RecommendedWine>>([_tWine]));
        return buildBloc();
      },
      act: (bloc) => bloc.add(HomeStarted()),
      verify: (_) => verify(() => mockLoadFavoriteIds()).called(1),
    );

    blocTest<HomeBloc, HomeState>(
      'is_favorite da API vale quando o cache não conhece o vinho',
      build: () {
        stubRecommendations(Try.success<List<RecommendedWine>>(
          [_tWine.copyWith(isFavorite: true)],
        ));
        return buildBloc();
      },
      act: (bloc) => bloc.add(HomeStarted()),
      expect: () => [
        _loadedWith(RecommendationsStatus.loading),
        _loadedWith(RecommendationsStatus.loaded).having(
            (s) => s.recommendations.single.isFavorite, 'isFavorite', isTrue),
      ],
    );

    blocTest<HomeBloc, HomeState>(
      'cache carregado prevalece sobre is_favorite da API',
      build: () {
        when(() => mockWatchFavoriteIds.current)
            .thenReturn(const FavoriteIds(isLoaded: true));
        stubRecommendations(Try.success<List<RecommendedWine>>(
          [_tWine.copyWith(isFavorite: true)],
        ));
        return buildBloc();
      },
      act: (bloc) => bloc.add(HomeStarted()),
      expect: () => [
        _loadedWith(RecommendationsStatus.loading),
        _loadedWith(RecommendationsStatus.loaded).having(
            (s) => s.recommendations.single.isFavorite, 'isFavorite', isFalse),
      ],
      verify: (_) => verifyNever(() => mockLoadFavoriteIds()),
    );

    final controller = StreamController<FavoriteIds>.broadcast();
    blocTest<HomeBloc, HomeState>(
      'reflete mudanças do cache feitas em outras telas',
      build: () {
        when(() => mockWatchFavoriteIds())
            .thenAnswer((_) => controller.stream);
        stubRecommendations(Try.success<List<RecommendedWine>>([_tWine]));
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(HomeStarted());
        await Future<void>.delayed(Duration.zero);
        controller.add(const FavoriteIds(ids: {'100003'}, isLoaded: true));
      },
      wait: const Duration(milliseconds: 10),
      expect: () => [
        _loadedWith(RecommendationsStatus.loading),
        _loadedWith(RecommendationsStatus.loaded).having(
            (s) => s.recommendations.single.isFavorite, 'isFavorite', isFalse),
        _loadedWith(RecommendationsStatus.loaded).having(
            (s) => s.recommendations.single.isFavorite, 'isFavorite', isTrue),
      ],
      tearDown: controller.close,
    );

    blocTest<HomeBloc, HomeState>(
      'tentar novamente recarrega só a seção e aplica o cache de favoritos',
      build: () {
        when(() => mockWatchFavoriteIds.current).thenReturn(
          const FavoriteIds(ids: {'100003'}, isLoaded: true),
        );
        stubRecommendations(Try.success<List<RecommendedWine>>([_tWine]));
        return buildBloc();
      },
      seed: () => HomeLoaded(
        welcomeMessage: 'Vinum',
        currentUser: _tUser,
        recommendations: [_tWine.copyWith(isFavorite: true)],
        recommendationsStatus: RecommendationsStatus.error,
        recommendationsErrorMessage: 'home_recommendations_error_load',
      ),
      act: (bloc) => bloc.add(HomeStarted()),
      expect: () => [
        _loadedWith(RecommendationsStatus.loading)
            .having((s) => s.recommendationsErrorMessage, 'error', isNull),
        _loadedWith(RecommendationsStatus.loaded).having(
            (s) => s.recommendations.single.isFavorite, 'isFavorite', isTrue),
      ],
      verify: (_) {
        verifyNever(() => mockAuthRepository.getCurrentUser());
        // Destaques já carregados não são buscados de novo.
        verifyNever(() => mockGetWineHighlights(any()));
      },
    );

    blocTest<HomeBloc, HomeState>(
      'tentar novamente busca de novo os destaques que falharam',
      build: () {
        stubRecommendations(Try.success<List<RecommendedWine>>([_tWine]));
        return buildBloc();
      },
      seed: () => HomeLoaded(
        welcomeMessage: 'Vinum',
        currentUser: _tUser,
        recommendationsStatus: RecommendationsStatus.error,
        highlightsStatus: HighlightsStatus.unavailable,
      ),
      act: (bloc) => bloc.add(HomeStarted()),
      expect: () => [
        _loadedWith(RecommendationsStatus.loading),
        _loadedWith(RecommendationsStatus.loaded).having(
            (s) => s.highlightsStatus,
            'highlightsStatus',
            HighlightsStatus.loaded),
      ],
      verify: (_) => verify(() => mockGetWineHighlights(any())).called(1),
    );
  });

  group('HomeRecommendationFavoriteToggled', () {
    blocTest<HomeBloc, HomeState>(
      'favorita de forma otimista e chama a API',
      build: () {
        stubSetFavorite(Try.success(true));
        return buildBloc();
      },
      seed: () => HomeLoaded(
        welcomeMessage: 'Vinum',
        recommendations: const [_tWine],
      ),
      act: (bloc) =>
          bloc.add(HomeRecommendationFavoriteToggled(wineId: _tWine.id)),
      expect: () => [
        isA<HomeLoaded>()
            .having((s) => s.recommendations.single.isFavorite, 'isFavorite',
                isTrue)
            .having((s) => s.favoriteErrorMessage, 'error', isNull),
      ],
      verify: (_) {
        final params = verify(() => mockSetFavorite(captureAny()))
            .captured
            .single as SetFavoriteParams;
        expect(params.wineId, _tWine.id);
        expect(params.isFavorite, isTrue);
      },
    );

    blocTest<HomeBloc, HomeState>(
      'falha -> volta o estado e sinaliza o erro',
      build: () {
        stubSetFavorite(Try.reject<bool>(
          KnownFailure(FavoriteFailureCode.server, null),
        ));
        return buildBloc();
      },
      seed: () => HomeLoaded(
        welcomeMessage: 'Vinum',
        recommendations: [_tWine.copyWith(isFavorite: true)],
      ),
      act: (bloc) =>
          bloc.add(HomeRecommendationFavoriteToggled(wineId: _tWine.id)),
      expect: () => [
        isA<HomeLoaded>().having((s) => s.recommendations.single.isFavorite,
            'isFavorite', isFalse),
        isA<HomeLoaded>()
            .having((s) => s.recommendations.single.isFavorite, 'isFavorite',
                isTrue)
            .having((s) => s.favoriteErrorMessage, 'error',
                'favorite_toggle_error'),
      ],
    );

    blocTest<HomeBloc, HomeState>(
      '401 -> logout e HomeSessionExpired',
      build: () {
        stubSetFavorite(Try.reject<bool>(
          KnownFailure(FavoriteFailureCode.unauthorized, null),
        ));
        return buildBloc();
      },
      seed: () => HomeLoaded(
        welcomeMessage: 'Vinum',
        recommendations: const [_tWine],
      ),
      act: (bloc) =>
          bloc.add(HomeRecommendationFavoriteToggled(wineId: _tWine.id)),
      expect: () => [
        isA<HomeLoaded>(),
        isA<HomeSessionExpired>(),
      ],
      verify: (_) => verify(() => mockLogout()).called(1),
    );
  });

  group('HomeHighlightFavoriteToggled', () {
    const highlight = HighlightWine(id: '200', name: 'Catena Malbec');

    blocTest<HomeBloc, HomeState>(
      'favorita o destaque pela API (e o mesmo vinho nas recomendações)',
      build: () {
        stubSetFavorite(Try.success(true));
        return buildBloc();
      },
      seed: () => HomeLoaded(
        welcomeMessage: 'Vinum',
        recommendations: const [
          RecommendedWine(id: '200', name: 'Catena', affinityPercentage: 80),
        ],
        highlights: const [highlight],
      ),
      act: (bloc) => bloc.add(HomeHighlightFavoriteToggled(wineId: '200')),
      expect: () => [
        isA<HomeLoaded>()
            .having((s) => s.highlights.single.isFavorite, 'highlight', isTrue)
            .having((s) => s.recommendations.single.isFavorite,
                'recommendation', isTrue),
      ],
      verify: (_) {
        final params = verify(() => mockSetFavorite(captureAny()))
            .captured
            .single as SetFavoriteParams;
        expect(params.wineId, '200');
        expect(params.isFavorite, isTrue);
      },
    );

    blocTest<HomeBloc, HomeState>(
      'falha -> volta o destaque e sinaliza o erro',
      build: () {
        stubSetFavorite(Try.reject<bool>(
          KnownFailure(FavoriteFailureCode.server, null),
        ));
        return buildBloc();
      },
      seed: () => HomeLoaded(
        welcomeMessage: 'Vinum',
        highlights: const [highlight],
      ),
      act: (bloc) => bloc.add(HomeHighlightFavoriteToggled(wineId: '200')),
      expect: () => [
        isA<HomeLoaded>()
            .having((s) => s.highlights.single.isFavorite, 'fav', isTrue),
        isA<HomeLoaded>()
            .having((s) => s.highlights.single.isFavorite, 'fav', isFalse)
            .having((s) => s.favoriteErrorMessage, 'error',
                'favorite_toggle_error'),
      ],
    );
  });
}
