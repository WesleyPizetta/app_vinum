---
name: flutter-testing
description: "Scaffold, write, and maintain Flutter unit tests, BLoC tests, and widget tests. Use when: writing unit tests for use cases or repositories, testing BLoCs with bloc_test and mocktail, creating widget tests for pages or components, or mocking dependencies."
---

# Flutter Unit, BLoC, and Widget Testing Guidelines

Use this skill when creating or updating unit tests, BLoC tests, and widget tests for the `app_vinum` project.

---

## 1. Unit Testing Strategy

### A. Testing Use Cases & Repositories (`mocktail`)

```dart
import 'package:essentials/essentials.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vinum/feature/wine/domain/entity/wine.dart';
import 'package:vinum/feature/wine/domain/repository/wine_repository.dart';
import 'package:vinum/feature/wine/domain/usecase/get_wine_by_id.dart';

class MockWineRepository extends Mock implements WineRepository {}

void main() {
  late MockWineRepository mockRepository;
  late GetWineById useCase;

  setUp(() {
    mockRepository = MockWineRepository();
    useCase = GetWineById(mockRepository);
  });

  const tWine = Wine(
    id: 'wine_123',
    name: 'Château Margaux',
    winery: 'Margaux',
    region: 'Bordeaux',
    country: 'França',
    grape: 'Cabernet Sauvignon',
    vintage: 2018,
    rating: 4.8,
    imageUrl: 'https://example.com/wine.png',
    description: 'Vinho tinto clássico',
  );

  test('deve retornar Try.success com o vinho quando a busca for bem-sucedida', () async {
    // Arrange
    when(() => mockRepository.getWineById('wine_123'))
        .thenAnswer((_) async => Try.success(tWine));

    // Act
    final result = await useCase(const GetWineByIdParams(id: 'wine_123'));

    // Assert
    expect(result.isSuccess, isTrue);
    result.fold(
      (failure) => fail('Não deveria falhar'),
      (wine) => expect(wine.id, equals('wine_123')),
    );
    verify(() => mockRepository.getWineById('wine_123')).called(1);
  });
}
```

---

## 2. BLoC Testing Strategy (`bloc_test`)

Always use `blocTest<Bloc, State>` with `mocktail` for BLoC verification:

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:essentials/essentials.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vinum/feature/wine/domain/usecase/get_wines.dart';
import 'package:vinum/feature/wine/presentation/bloc/wine_list_bloc.dart';
import 'package:vinum/feature/wine/presentation/bloc/wine_list_event.dart';
import 'package:vinum/feature/wine/presentation/bloc/wine_list_state.dart';

class MockGetWines extends Mock implements GetWines {}

void main() {
  late MockGetWines mockGetWines;

  setUp(() {
    mockGetWines = MockGetWines();
  });

  blocTest<WineListBloc, WineListState>(
    'emite [WineListLoading, WineListLoaded] quando busca vinhos com sucesso',
    build: () {
      when(() => mockGetWines()).thenAnswer((_) async => Try.success([]));
      return WineListBloc(mockGetWines);
    },
    act: (bloc) => bloc.add(WineListStarted()),
    expect: () => [
      isA<WineListLoading>(),
      isA<WineListLoaded>().having((s) => s.wines, 'wines', isEmpty),
    ],
    verify: (_) {
      verify(() => mockGetWines()).called(1);
    },
  );
}
```

---

## 3. Widget Testing Strategy

### A. Wrapping Widget under Test
Wrap widgets with `MaterialApp`, `AppLocalizationDelegate`, and registered DI containers:

```dart
import 'package:essentials/essentials.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vinum/core/di/vinum_container.dart';

Widget buildTestableWidget(Widget child) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizationDelegate(supportedLocales: [Locale('pt', 'BR')]),
      ...GlobalMaterialLocalizations.delegates,
    ],
    supportedLocales: const [Locale('pt', 'BR')],
    locale: const Locale('pt', 'BR'),
    home: child,
  );
}
```

### B. Widget Test with Mock / Fake BLoC
```dart
testWidgets('exibe tela de login com botões de ação', (tester) async {
  await tester.pumpWidget(buildTestableWidget(const LoginPage()));
  await tester.pumpAndSettle();

  expect(find.byType(TextFormField), findsNWidgets(2));
  expect(find.byType(ElevatedButton), findsWidgets);
});
```

---

## 4. Testing Checklist

- [ ] **Unit Tests**: Test logic using `Try.success` and `Try.reject` assertions.
- [ ] **BLoC Tests**: Verify states emission sequence (`Loading` $\rightarrow$ `Success` / `Error`).
- [ ] **Widget Tests**: Ensure DI mocks (`ApplicationContainer.reset()`) are torn down in `tearDown` or `tearDownAll`.
- [ ] **Mocktail Fallbacks**: Use `registerFallbackValue(...)` in `setUpAll` if passing custom objects to `any()`.
- [ ] **Execution**: Code passes `flutter test`.
