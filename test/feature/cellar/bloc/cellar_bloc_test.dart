import 'package:bloc_test/bloc_test.dart';
import 'package:essentials/essentials.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vinum/feature/auth/domain/usecase/logout.dart';
import 'package:vinum/feature/cellar/domain/entity/cellar_failure_code.dart';
import 'package:vinum/feature/cellar/domain/entity/cellar_review.dart';
import 'package:vinum/feature/cellar/domain/entity/cellar_reviews_page.dart';
import 'package:vinum/feature/cellar/domain/usecase/get_my_reviews.dart';
import 'package:vinum/feature/cellar/presentation/bloc/cellar_bloc.dart';
import 'package:vinum/feature/cellar/presentation/bloc/cellar_event.dart';
import 'package:vinum/feature/cellar/presentation/bloc/cellar_state.dart';

class MockGetMyReviews extends Mock implements GetMyReviews {}

class MockLogout extends Mock implements Logout {}

CellarReview _review(int id, {double rating = 8}) => CellarReview(
      id: 'r$id',
      wineId: '$id',
      rating: rating,
      createdAt: DateTime.utc(2026, 9, 30),
    );

List<CellarReview> _reviews(int from, int count) =>
    List.generate(count, (i) => _review(from + i));

Try<CellarReviewsPage> _page(
  List<CellarReview> items, {
  int offset = 0,
  bool hasMore = true,
}) =>
    Try.success<CellarReviewsPage>(CellarReviewsPage(
      items: items,
      offset: offset,
      hasMore: hasMore,
      nextOffset: hasMore ? offset + items.length : null,
    ));

CellarLoaded _loadedState(
  List<CellarReview> items, {
  bool hasMore = false,
  int? nextOffset,
}) =>
    CellarLoaded(
      items: items,
      hasMore: hasMore,
      nextOffset: nextOffset ?? items.length,
    );

TypeMatcher<CellarLoaded> _loaded({
  List<String>? ids,
  bool? hasMore,
  int? nextOffset,
}) {
  var matcher = isA<CellarLoaded>();
  if (ids != null) {
    matcher =
        matcher.having((s) => s.items.map((r) => r.id).toList(), 'ids', ids);
  }
  if (hasMore != null) {
    matcher = matcher.having((s) => s.hasMore, 'hasMore', hasMore);
  }
  if (nextOffset != null) {
    matcher = matcher.having((s) => s.nextOffset, 'nextOffset', nextOffset);
  }
  return matcher;
}

List<String> _ids(int from, int count) =>
    List.generate(count, (i) => 'r${from + i}');

void main() {
  late MockGetMyReviews mockGetMyReviews;
  late MockLogout mockLogout;

  /// Respostas por offset pedido.
  late Map<int, Try<CellarReviewsPage>> responses;

  setUpAll(() {
    registerFallbackValue(const GetMyReviewsParams());
  });

  setUp(() {
    mockGetMyReviews = MockGetMyReviews();
    mockLogout = MockLogout();
    responses = {};

    when(() => mockLogout()).thenAnswer((_) async => Try.success<void>(null));
    when(() => mockGetMyReviews(any())).thenAnswer((invocation) async {
      final params =
          invocation.positionalArguments.first as GetMyReviewsParams;
      return responses[params.offset] ??
          Try.reject<CellarReviewsPage>(UnknownFailure('sem stub'));
    });
  });

  CellarBloc buildBloc() => CellarBloc(mockGetMyReviews, mockLogout);

  group('CellarStarted', () {
    blocTest<CellarBloc, CellarState>(
      'carrega a primeira página (offset 0, limit 20)',
      build: () {
        responses[0] = _page(_reviews(1, 20));
        return buildBloc();
      },
      act: (bloc) => bloc.add(CellarStarted()),
      expect: () => [
        isA<CellarLoading>(),
        _loaded(ids: _ids(1, 20), hasMore: true, nextOffset: 20),
      ],
      verify: (_) {
        final params = verify(() => mockGetMyReviews(captureAny()))
            .captured
            .single as GetMyReviewsParams;
        expect(params.offset, 0);
        expect(params.limit, CellarBloc.pageSize);
      },
    );

    blocTest<CellarBloc, CellarState>(
      'sem avaliações -> vazio',
      build: () {
        responses[0] = _page(const [], hasMore: false);
        return buildBloc();
      },
      act: (bloc) => bloc.add(CellarStarted()),
      expect: () => [isA<CellarLoading>(), isA<CellarEmpty>()],
    );

    blocTest<CellarBloc, CellarState>(
      'remove avaliações duplicadas',
      build: () {
        responses[0] = _page(
          [_review(1), _review(2), _review(1)],
          hasMore: false,
        );
        return buildBloc();
      },
      act: (bloc) => bloc.add(CellarStarted()),
      expect: () => [
        isA<CellarLoading>(),
        _loaded(ids: ['r1', 'r2'], hasMore: false),
      ],
    );

    blocTest<CellarBloc, CellarState>(
      'erro de servidor -> mensagem de servidor',
      build: () {
        responses[0] = Try.reject<CellarReviewsPage>(
          KnownFailure(CellarFailureCode.server, null),
        );
        return buildBloc();
      },
      act: (bloc) => bloc.add(CellarStarted()),
      expect: () => [
        isA<CellarLoading>(),
        isA<CellarError>()
            .having((s) => s.message, 'message', 'cellar_error_server'),
      ],
    );

    blocTest<CellarBloc, CellarState>(
      'falha de conexão -> mensagem de conexão',
      build: () {
        responses[0] =
            Try.reject<CellarReviewsPage>(UnknownFailure(Exception('off')));
        return buildBloc();
      },
      act: (bloc) => bloc.add(CellarStarted()),
      expect: () => [
        isA<CellarLoading>(),
        isA<CellarError>()
            .having((s) => s.message, 'message', 'cellar_error_connection'),
      ],
    );

    blocTest<CellarBloc, CellarState>(
      '401 -> logout e sessão expirada',
      build: () {
        responses[0] = Try.reject<CellarReviewsPage>(
          KnownFailure(CellarFailureCode.unauthorized, null),
        );
        return buildBloc();
      },
      act: (bloc) => bloc.add(CellarStarted()),
      expect: () => [
        isA<CellarLoading>(),
        isA<CellarSessionExpired>()
            .having((s) => s.message, 'message', 'session_expired'),
      ],
      verify: (_) => verify(() => mockLogout()).called(1),
    );
  });

  group('CellarLoadMoreRequested', () {
    blocTest<CellarBloc, CellarState>(
      'anexa a próxima página e encerra quando não há mais',
      build: () {
        responses[20] = _page(_reviews(21, 5), offset: 20, hasMore: false);
        return buildBloc();
      },
      seed: () => _loadedState(_reviews(1, 20), hasMore: true, nextOffset: 20),
      act: (bloc) => bloc.add(CellarLoadMoreRequested()),
      expect: () => [
        isA<CellarLoaded>()
            .having((s) => s.isLoadingMore, 'isLoadingMore', isTrue),
        _loaded(ids: _ids(1, 25), hasMore: false)
            .having((s) => s.isLoadingMore, 'isLoadingMore', isFalse),
      ],
    );

    blocTest<CellarBloc, CellarState>(
      'erro ao carregar mais mantém os itens e mostra o rodapé de erro',
      build: () {
        responses[20] = Try.reject<CellarReviewsPage>(
          KnownFailure(CellarFailureCode.server, null),
        );
        return buildBloc();
      },
      seed: () => _loadedState(_reviews(1, 20), hasMore: true, nextOffset: 20),
      act: (bloc) => bloc.add(CellarLoadMoreRequested()),
      expect: () => [
        isA<CellarLoaded>()
            .having((s) => s.isLoadingMore, 'isLoadingMore', isTrue),
        _loaded(ids: _ids(1, 20)).having(
            (s) => s.loadMoreError, 'loadMoreError', 'cellar_load_more_error'),
      ],
    );

    blocTest<CellarBloc, CellarState>(
      'página sem itens novos encerra a paginação',
      build: () {
        responses[20] = _page(_reviews(1, 3), offset: 20);
        return buildBloc();
      },
      seed: () => _loadedState(_reviews(1, 20), hasMore: true, nextOffset: 20),
      act: (bloc) => bloc.add(CellarLoadMoreRequested()),
      expect: () => [
        isA<CellarLoaded>(),
        _loaded(ids: _ids(1, 20), hasMore: false),
      ],
    );

    blocTest<CellarBloc, CellarState>(
      'ignora quando não há mais páginas',
      build: buildBloc,
      seed: () => _loadedState(_reviews(1, 3)),
      act: (bloc) => bloc.add(CellarLoadMoreRequested()),
      expect: () => const <CellarState>[],
      verify: (_) => verifyNever(() => mockGetMyReviews(any())),
    );
  });

  group('CellarRefreshed', () {
    blocTest<CellarBloc, CellarState>(
      'recarrega do offset 0 mantendo a lista durante o refresh',
      build: () {
        responses[0] = _page([_review(9), ..._reviews(1, 2)], hasMore: false);
        return buildBloc();
      },
      seed: () => _loadedState(_reviews(1, 2)),
      act: (bloc) => bloc.add(CellarRefreshed()),
      expect: () => [
        _loaded(ids: ['r1', 'r2'])
            .having((s) => s.isRefreshing, 'isRefreshing', isTrue),
        _loaded(ids: ['r9', 'r1', 'r2'])
            .having((s) => s.isRefreshing, 'isRefreshing', isFalse),
      ],
    );

    blocTest<CellarBloc, CellarState>(
      'falha no refresh preserva os itens e sinaliza o erro',
      build: () {
        responses[0] =
            Try.reject<CellarReviewsPage>(UnknownFailure(Exception('off')));
        return buildBloc();
      },
      seed: () => _loadedState(_reviews(1, 2)),
      act: (bloc) => bloc.add(CellarRefreshed()),
      expect: () => [
        _loaded(ids: ['r1', 'r2'])
            .having((s) => s.isRefreshing, 'isRefreshing', isTrue),
        _loaded(ids: ['r1', 'r2'])
            .having((s) => s.isRefreshing, 'isRefreshing', isFalse)
            .having((s) => s.refreshError, 'refreshError',
                'cellar_error_connection'),
      ],
    );

    blocTest<CellarBloc, CellarState>(
      'última avaliação excluída -> vazio',
      build: () {
        responses[0] = _page(const [], hasMore: false);
        return buildBloc();
      },
      seed: () => _loadedState([_review(1)]),
      act: (bloc) => bloc.add(CellarRefreshed()),
      expect: () => [
        isA<CellarLoaded>(),
        isA<CellarEmpty>(),
      ],
    );

    blocTest<CellarBloc, CellarState>(
      'no estado vazio recarrega do zero',
      build: () {
        responses[0] = _page([_review(1)], hasMore: false);
        return buildBloc();
      },
      seed: () => CellarEmpty(),
      act: (bloc) => bloc.add(CellarRefreshed()),
      expect: () => [
        isA<CellarLoading>(),
        _loaded(ids: ['r1']),
      ],
    );
  });

  group('CellarLoaded.averageRating', () {
    test('média das notas carregadas', () {
      final state = CellarLoaded(
        items: [_review(1, rating: 8), _review(2, rating: 7)],
        hasMore: false,
        nextOffset: 2,
      );
      expect(state.averageRating, 7.5);
    });

    test('sem itens -> null', () {
      final state = CellarLoaded(items: const [], hasMore: true, nextOffset: 0);
      expect(state.averageRating, isNull);
    });
  });
}
