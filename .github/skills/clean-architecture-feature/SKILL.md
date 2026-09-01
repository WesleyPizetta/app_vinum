---
name: clean-architecture-feature
description: Build Flutter features using BLoC state management, clean architecture layers (domain, data, presentation), Try<T> error handling, and VinumContainer DI. References template examples in the examples/ folder.
---

# Clean Architecture + BLoC Feature Workflow

Use this skill when scaffolding or expanding a feature inside `lib/feature/<feature_name>/` in the `app_vinum` codebase.

## Reference Code Examples

Before building a new feature, inspect the reference implementation files in `examples/`:

- **Domain Repository Interface**: [examples/sample_repository.dart](examples/sample_repository.dart)
- **Use Case**: [examples/sample_usecase.dart](examples/sample_usecase.dart)
- **BLoC & Sealed Events / States**: [examples/sample_bloc.dart](examples/sample_bloc.dart)
- **Page & BLoC Binding**: [examples/sample_page.dart](examples/sample_page.dart)

---

## Architecture Structure

Each feature in `lib/feature/<feature_name>/` is divided into three Clean Architecture layers:

```text
lib/feature/<feature_name>/
├── domain/
│   ├── entity/          # Business entities (pure Dart)
│   ├── repository/      # Abstract repository interface returning Future<Try<T>>
│   └── usecase/         # Classes implementing UseCase<T, Params> or UnitUseCase<T>
├── data/
│   ├── api/             # Chopper services (annotated with @ChopperApi)
│   ├── datasource/      # Abstract & concrete datasources (Mock / Remote)
│   ├── model/           # DTOs with fromJson, toJson, toEntity, fromEntity
│   └── repository/      # Repository implementation returning Try.success/reject
└── presentation/
    ├── bloc/            # Feature BLoC, sealed Events, sealed States
    ├── page/            # Top-level Page widget with BlocProvider/BlocBuilder
    └── widget/          # Reusable widgets for this feature
```

---

## Implementation Workflow

Follow this strict inner-to-outer sequence:

### 1. Domain Layer (`domain/`)
- Define entities in `domain/entity/`.
- Define abstract repository interface in `domain/repository/` returning `Future<Try<T>>`. See [examples/sample_repository.dart](examples/sample_repository.dart).
- Implement use cases in `domain/usecase/` extending `UseCase<T, Params>` or `UnitUseCase<T>` from `package:essentials/essentials.dart`. See [examples/sample_usecase.dart](examples/sample_usecase.dart).

### 2. Data Layer (`data/`)
- Create API services (`@ChopperApi`) in `data/api/` if backend integration is required.
- Create datasources in `data/datasource/` (e.g. `mock_datasource.dart` or `remote_datasource.dart`).
- Implement repository in `data/repository/` returning `Try.success(data)` or `Try.reject(failure)`.

### 3. Registration & Navigation
- Register services, datasources, repositories, use cases, and BLoC factories in `lib/core/di/vinum_container.dart`.
- Register route constants in `lib/core/navigation/application_route.dart` and `lib/vinum_app.dart`.
- Add all new UI strings to `lang/pt_BR.json` and `lang/en_US.json`.

### 4. Presentation Layer (`presentation/`)
- Define sealed classes for events and states, and BLoC receiving use cases in constructor. See [examples/sample_bloc.dart](examples/sample_bloc.dart).
- Create Page widget using `BlocProvider` and `BlocBuilder`/`BlocListener` with pattern matching on states. See [examples/sample_page.dart](examples/sample_page.dart).

---

## Quality & Validation Checklist

- [ ] `domain` layer has no imports from `data` or `presentation`.
- [ ] Fallible operations return `Try<T>` from `package:essentials/essentials.dart`.
- [ ] Spacing, border radius, and icon sizes use `Dimens` (e.g., `Dimens.spacing16`, `Dimens.radiusMedium`).
- [ ] Colors use `VinumPalette` or `Theme.of(context).colorScheme` (avoid hardcoded `Color(...)`).
- [ ] Dependencies are registered in `lib/core/di/vinum_container.dart`.
- [ ] Interface copy is added to both `lang/pt_BR.json` and `lang/en_US.json`.
- [ ] Code is formatted with `dart format` and analyzed with `flutter analyze`.

❌ Hardcoded colors like `Color(0xFF4A90A4)` → Use `Theme.of(context).colorScheme` or `VinumPalette`
❌ Magic numbers like `padding: 16` → Use `Dimens.spacing16` from `package:essentials/essentials.dart`

---

## Quick Reference

| Action | Pattern |
|--------|---------|
| Dispatch event | `context.read<Bloc>().add(Event())` |
| Watch state inline | `context.watch<Bloc>().state` |
| Spacing & Sizing | `Dimens.spacing16`, `Dimens.spacing24`, `Dimens.radiusMedium` |
| Listen + Build | `BlocConsumer` |
| Listen only | `BlocListener` |
| Build only | `BlocBuilder` |

---

## Checklist Before Submitting

- [ ] Events/States use Dart 3 `sealed class` pattern
- [ ] Async flow handles Loading → Success/Error states via `Try<T>`
- [ ] No business logic in UI
- [ ] No SDK or API calls outside datasources
- [ ] Zero hardcoded colors/spacing (use `Dimens` and `VinumPalette` / `ColorScheme`)
- [ ] Code formatted with `dart format`