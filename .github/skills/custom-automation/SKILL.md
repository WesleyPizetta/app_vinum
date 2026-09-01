---
name: custom-automation
description: "Scaffold, write, run, and maintain custom task automation scripts for Flutter/Dart development. Use when: generating build runner code, running code formatters, executing static analysis, running unit/widget tests, preparing release builds, or automating repetitive project workflows."
---

# Custom Automation Workflow for app_vinum

Use this skill when creating or running automated tasks, scripts, and build workflows for the `app_vinum` project.

---

## Standard Project Commands

### 1. Code Generation (`build_runner`)
Run whenever Chopper API services (`@ChopperApi`), models, or generated files are modified:

```powershell
dart run build_runner build --delete-conflicting-outputs
```

### 2. Static Analysis & Linting
Run to verify code quality and compliance with `analysis_options.yaml`:

```powershell
flutter analyze
```

### 3. Code Formatting
Format all Dart files in the workspace:

```powershell
dart format .
```

### 4. Running Unit & Widget Tests
Execute tests for a specific feature or across the entire test suite:

```powershell
# Specific test file
flutter test test/feature/auth/presentation/bloc/login_bloc_test.dart

# All tests
flutter test
```

### 5. Application Launch (Dev Environment)
Launch local development flavor pointing to `main_dev.dart`:

```powershell
flutter run -t lib/main_dev.dart
```

---

## Automation Script Layout

When creating reusable automation scripts, place them under `.github/skills/custom-automation/scripts/`:

```text
.github/skills/custom-automation/
├── SKILL.md
└── scripts/
    ├── check_quality.ps1    # Runs format, analyze, and tests in sequence
    └── generate_code.ps1    # Runs build_runner with conflicting outputs flag
```

### Example Quality Check Script (`check_quality.ps1`)

```powershell
Write-Host "1/3 Running Dart Format..." -ForegroundColor Cipher
dart format --set-exit-if-changed .

Write-Host "2/3 Running Flutter Analyze..." -ForegroundColor Cipher
flutter analyze

Write-Host "3/3 Running Flutter Tests..." -ForegroundColor Cipher
flutter test
```

---

## Checklist for Automation Execution

- [ ] Command is non-destructive to uncommitted manual code changes.
- [ ] Generated files (`*.chopper.dart`, etc.) are not committed without prior `build_runner` verification.
- [ ] Commands run in the workspace root directory (`app_vinum`).
- [ ] Script output is checked for zero exit codes before proceeding.
