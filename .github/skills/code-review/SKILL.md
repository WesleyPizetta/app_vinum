---
name: code-review
description: Perform a comprehensive code review of Dart and Flutter changes in app_vinum. Use when: reviewing PRs, auditing code quality, checking Clean Architecture compliance, verifying BLoC state management, reviewing UI layouts, or validating design system usage.
---

# Code Review Guidelines for app_vinum

Use this skill when auditing or reviewing code changes in this codebase. Reviews must be constructive, precise, and focused on maintaining code quality, architectural consistency, and security.

---

## Code Review Checklist

### 1. Architecture & Layer Boundaries
- [ ] **Clean Architecture Isolation**: The `domain` layer contains pure Dart code. It does NOT import anything from `data` or `presentation`.
- [ ] **Data Access via Interfaces**: Presentation widgets and BLoCs reach data through domain use cases or repository abstractions, never by instantiating concrete data classes directly.
- [ ] **Dependency Injection**: New services, repositories, use cases, and BLoC factories are registered in `lib/core/di/vinum_container.dart` using constructor injection.
- [ ] **Error Handling with `Try<T>`**: Fallible operations return `Future<Try<T>>` from `package:essentials/essentials.dart` and map errors appropriately to presentation states.

### 2. State Management (BLoC)
- [ ] **Dart 3 Sealed Classes**: Events and States use `sealed class` hierarchies for type safety and exhaustive pattern matching in `switch` statements.
- [ ] **Loading State Emission**: Async operations in BLoCs emit a `Loading` state before awaiting data/use cases, then emit `Success`/`Loaded` or `Error`.
- [ ] **UI Logic Separation**: Widgets only dispatch events (`context.read<Bloc>().add(...)`) and render states (`BlocBuilder`/`BlocListener`). No business or data logic exists in widgets.

### 3. UI & Layout Best Practices
- [ ] **Linear Layout First**: UI layouts use `Column`, `Row`, `Wrap`, or `Flex` for standard flow. `Stack` + `Positioned` is used ONLY for true visual overlays (e.g., badges on avatars).
- [ ] **Design System Constants (`Dimens`)**: Spacing, padding, margins, icon sizes, and border radii use `Dimens` constants (e.g., `Dimens.spacing16`, `Dimens.radiusMedium`). Zero magic numbers (`16.0`, `24.0`).
- [ ] **Color System (`VinumPalette`)**: Colors use `VinumPalette` or `Theme.of(context).colorScheme`. No hardcoded hex values (`Color(0xFF...)`) or raw `Colors.blue`.

### 4. Internationalization (i18n)
- [ ] **Dual Language Support**: All new user-facing strings are added to both `lang/pt_BR.json` and `lang/en_US.json`.
- [ ] **No Hardcoded Copy**: UI widgets do not contain raw string literals for user copy.

### 5. Generated Code & API Services
- [ ] **Chopper Services**: Changes to API services are annotated with `@ChopperApi`. Generated files (`*.chopper.dart`) are updated via `dart run build_runner build --delete-conflicting-outputs` and are not edited manually.
- [ ] **Data Source Strategy**: `Wine` feature continues to use `WineMockDatasource` unless explicitly instructed to enable remote API integration.

### 6. Security & Secrets Protection
- [ ] **No Hardcoded Credentials**: No API keys, tokens, Supabase keys, Firebase credentials, Google OAuth secrets, or keystore passphrases are committed in source code.
- [ ] **Environment Variables**: New configuration items are referenced via `dotenv.env[...]` and documented in `.env.example`.

### 7. Code Quality & Format
- [ ] **Formatting**: Code is formatted with `dart format`.
- [ ] **Static Analysis**: Code passes `flutter analyze` with zero errors or warnings.

---

## Review Response Template

When delivering a review, structure the feedback as follows:

```markdown
## Code Review Summary
[Brief description of the changes reviewed and general assessment]

### 🔴 Critical Issues (Blocking)
- [File link](path/file.dart#L10): Issue description and suggested fix

### 🟡 Suggestions & Improvements (Non-blocking)
- [File link](path/file.dart#L25): Suggestion for cleaner/more idiomatic code

### 📋 Checklist Verification
- [x] Clean Architecture boundaries
- [x] BLoC sealed events/states & Loading state
- [x] Design System (`Dimens` & `VinumPalette`)
- [x] Linear layout (`Column`/`Row` over `Stack`)
- [x] i18n (`pt_BR.json` and `en_US.json`)
- [x] Security & Secrets
```
