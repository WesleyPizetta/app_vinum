import 'package:bloc_test/bloc_test.dart';
import 'package:essentials/essentials.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vinum/feature/home/domain/entity/recommendation_failure_code.dart';
import 'package:vinum/feature/home/domain/entity/wine_match.dart';
import 'package:vinum/feature/home/domain/entity/wine_match_reason.dart';
import 'package:vinum/feature/home/domain/usecase/get_wine_match.dart';
import 'package:vinum/feature/wine/presentation/bloc/wine_match_bloc.dart';
import 'package:vinum/feature/wine/presentation/bloc/wine_match_event.dart';
import 'package:vinum/feature/wine/presentation/bloc/wine_match_state.dart';

class MockGetWineMatch extends Mock implements GetWineMatch {}

const _tMatch = WineMatch(
  wineId: '1',
  matchPercent: 87,
  reasons: [
    WineMatchReason(code: WineMatchReasonCode.typeMatch, value: 'Red'),
    WineMatchReason(
      code: WineMatchReasonCode.acidityHigher,
      value: 'High',
      positive: false,
    ),
  ],
);

void main() {
  late MockGetWineMatch mockGetWineMatch;

  setUp(() => mockGetWineMatch = MockGetWineMatch());

  WineMatchBloc buildBloc() => WineMatchBloc(mockGetWineMatch);

  void stub(Try<WineMatch> result) =>
      when(() => mockGetWineMatch(any())).thenAnswer((_) async => result);

  blocTest<WineMatchBloc, WineMatchState>(
    'carrega a afinidade e os motivos do vinho',
    build: () {
      stub(Try.success<WineMatch>(_tMatch));
      return buildBloc();
    },
    act: (bloc) => bloc.add(WineMatchStarted(wineId: '1')),
    expect: () => [
      isA<WineMatchLoading>(),
      isA<WineMatchLoaded>()
          .having((s) => s.match.matchPercent, 'matchPercent', 87)
          .having((s) => s.match.reasons, 'reasons', hasLength(2)),
    ],
    verify: (_) => verify(() => mockGetWineMatch('1')).called(1),
  );

  blocTest<WineMatchBloc, WineMatchState>(
    '409 ONBOARDING_REQUIRED -> seção oculta',
    build: () {
      stub(Try.reject<WineMatch>(
        KnownFailure(RecommendationFailureCode.onboardingRequired, null),
      ));
      return buildBloc();
    },
    act: (bloc) => bloc.add(WineMatchStarted(wineId: '1')),
    expect: () => [isA<WineMatchLoading>(), isA<WineMatchHidden>()],
  );

  blocTest<WineMatchBloc, WineMatchState>(
    '404 -> seção oculta',
    build: () {
      stub(Try.reject<WineMatch>(
        KnownFailure(RecommendationFailureCode.notFound, null),
      ));
      return buildBloc();
    },
    act: (bloc) => bloc.add(WineMatchStarted(wineId: '1')),
    expect: () => [isA<WineMatchLoading>(), isA<WineMatchHidden>()],
  );

  blocTest<WineMatchBloc, WineMatchState>(
    'falha de conexão -> erro com "tentar novamente"',
    build: () {
      stub(Try.reject<WineMatch>(UnknownFailure(Exception('off'))));
      return buildBloc();
    },
    act: (bloc) => bloc.add(WineMatchStarted(wineId: '1')),
    expect: () => [isA<WineMatchLoading>(), isA<WineMatchError>()],
  );
}
