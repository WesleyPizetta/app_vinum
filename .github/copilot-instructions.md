# Vinum Project Instructions

## Stack and Commands

- This is a Flutter application using Dart `^3.6.0`; follow the configured `flutter_lints` rules in `analysis_options.yaml`.
- Before completing Dart changes, run the narrowest relevant check: `flutter test <path>`, `flutter analyze`, and `dart format` on changed Dart files as appropriate.
- Use `flutter run -t lib/main_dev.dart` for local development. Keep `main_dev.dart` and `main_prod.dart` environment-specific; do not move secrets into source code.

## Architecture

- Preserve Clean Architecture inside `lib/feature/<feature>/`: `domain` contains pure entities, repository contracts, and use cases; `data` implements domain contracts and handles APIs, datasources, and models; `presentation` contains pages, widgets, and BLoCs.
- Presentation must reach data through domain use cases or repository abstractions, never by importing concrete data implementations.
- Model fallible operations with `Try<T>` from the internal `essentials` package and map failures to presentation states.
- Register new services, repositories, use cases, and BLoC factories in `lib/core/di/vinum_container.dart`. Keep constructor injection; do not create ad hoc global dependencies.
- Use `ApplicationRoute` for named routes and `VinumTheme`/`VinumPalette` from `essentials` for application styling.

## Project Conventions

- Implement state flows with BLoC events and states. Pages dispatch events and render states; BLoCs coordinate use cases and should remain independent of widgets.
- Add user-facing strings to both `lang/pt_BR.json` and `lang/en_US.json`; do not hard-code new interface copy in widgets.
- Chopper `*.chopper.dart` files are generated. Change the annotated API service, then regenerate with `dart run build_runner build --delete-conflicting-outputs`; do not manually edit generated files.
- Wine currently uses `WineMockDatasource`. Do not switch it to the remote datasource unless the task explicitly enables the Wine API integration.

## Secrets and Repository Hygiene

- Never print, commit, or hard-code credentials from `.env`, `.env.prod`, Firebase configuration, Google OAuth configuration, service-account files, keystores, or platform signing files.
- Keep changes focused. Do not modify platform configuration, dependency versions, generated code, or unrelated formatting unless the task requires it.

## References

- See [ARQUITETURA.md](../ARQUITETURA.md) for the full dependency and feature design.
- See [README.md](../README.md) for environment setup, OAuth/Firebase requirements, and branch workflow.
- See [TESTES.md](../TESTES.md) for testing guidance.
