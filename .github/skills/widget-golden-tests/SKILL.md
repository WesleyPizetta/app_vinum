---
name: widget-golden-tests
description: "Scaffold, write, run, and update Flutter widget golden tests for visual regression testing. Use when: writing golden tests for UI components, verifying visual appearance across screen sizes/themes, updating golden master images, or debugging golden test failures."
---

# Flutter Widget Golden Tests Workflow

Use this skill when creating, executing, or updating visual regression (Golden) tests in the `app_vinum` project.

---

## 1. Golden Test Structure & File Naming

Place golden tests inside `test/feature/<feature_name>/presentation/page/` or `test/core/widgets/`:

```text
test/
└── feature/
    └── wine/
        └── presentation/
            └── page/
                ├── wine_list_page_test.dart
                └── goldens/
                    ├── wine_list_page_light.png
                    └── wine_list_page_dark.png
```

---

## 2. Standard Golden Test Template

Golden tests require wrapping widgets in the application theme (`VinumTheme`) and localization delegates (`AppLocalizationDelegate`).

```dart
import 'package:essentials/essentials.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vinum/core/di/vinum_container.dart';
import 'package:vinum/feature/wine/presentation/page/wine_list_page.dart';

void main() {
  setUpAll(() {
    // Ensure binding is initialized for font loading and asset rendering
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  Widget createWidgetToTest(Widget child) {
    final theme = VinumTheme(VinumPalette());

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: theme.themeData,
      localizationsDelegates: const [
        AppLocalizationDelegate(
          supportedLocales: [Locale('pt', 'BR'), Locale('en', 'US')],
        ),
      ],
      supportedLocales: const [Locale('pt', 'BR')],
      home: child,
    );
  }

  testWidgets('WineListPage matches light theme golden image', (tester) async {
    // Set fixed surface size for consistent resolution across environments
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 2.625;

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(createWidgetToTest(const WineListPage()));
    await tester.pumpAndSettle();

    // Verify visual match against golden image
    await expectLater(
      find.byType(WineListPage),
      matchesGoldenFile('goldens/wine_list_page_light.png'),
    );
  });
}
```

---

## 3. Running & Updating Golden Tests

### Run Golden Tests
Verify existing golden images:

```powershell
flutter test --tags=golden
```

### Generate / Update Golden Master Images
Run when UI layout changes are intentional and golden master images need to be generated or refreshed:

```powershell
flutter test --update-goldens
```

---

## 4. Best Practices Checklist

- [ ] **Fixed Viewport Size**: Set explicit `tester.view.physicalSize` and `devicePixelRatio` to prevent platform-dependent rendering variations.
- [ ] **Reset View Settings**: Call `addTearDown` to reset physical size and device pixel ratio after test execution.
- [ ] **App Theme Wrapper**: Wrap tested widgets with `VinumTheme(VinumPalette())` and design system tokens.
- [ ] **Pump and Settle**: Call `await tester.pumpAndSettle()` before matching to ensure animations and asset loading complete.
- [ ] **Font & Asset Rendering**: Ensure custom fonts (`Amarante`, `Caveat`) render cleanly or are properly loaded in test setup.
