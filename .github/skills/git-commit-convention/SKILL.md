---
name: git-commit-convention
description: "Format git commit messages according to Conventional Commits and Gitflow Jira branch conventions. Use when: writing git commits, staging code changes, structuring commit messages, or preparing commits for pull requests."
---

# Git Commit Message Standards (Conventional Commits + Jira Gitflow)

Use this skill when staging, formatting, or creating Git commits for the `app_vinum` project.

---

## 1. Commit Structure

All commit messages MUST follow the Conventional Commits specification integrated with Jira ticket IDs extracted from the active branch name:

```text
<type>(<TICKET-ID>): <short summary in imperative mood>

<detailed description of changes>
- List itemized changes, technical decisions, or rationale
- Reference modified files, models, or state management updates
```

---

## 2. Extracting Ticket ID from Branch Name

Automate or parse the ticket identifier from the active Git branch:

| Branch Name Example | Extracted Scope (`TICKET-ID`) | Commit Header Example |
|---|---|---|
| `feat/VIN-15-add-dark-theme` | `VIN-15` | `feat(VIN-15): add dark theme support and settings page selector` |
| `EXEMPLO-15-tarefa-do-jira` | `EXEMPLO-15` | `feat(EXEMPLO-15): implement bottom navigation bar with animations` |
| `fix/VIN-42-login-session-leak` | `VIN-42` | `fix(VIN-42): persist auth tokens in secure storage` |
| `develop` / `main` (no ticket) | `core` or `<module>` | `refactor(core): extract reusable modal widgets` |

---

## 3. Allowed Commit Types (`<type>`)

- **`feat`**: A new feature or user-facing capability.
- **`fix`**: A bug fix or patch.
- **`docs`**: Documentation only changes (README, architecture, comments).
- **`style`**: Code style changes (formatting with `dart format`, missing semicolons, white-space).
- **`refactor`**: Code restructuring without changing behavior or adding features.
- **`test`**: Adding missing tests, golden tests, or correcting existing tests.
- **`chore`**: Maintenance tasks, dependencies (`pubspec.yaml`), Melos scripts, or build configurations.
- **`perf`**: Performance optimizations.
- **`ci`**: CI/CD pipeline changes (GitHub Actions, Fastlane).

---

## 4. Message Body Guidelines

The body section provides comprehensive context for code reviewers on GitHub/GitLab/Gitea:

- **Imperative Mood**: Use "add", "implement", "fix", "refactor" instead of "added", "implementing", "fixed".
- **Short Summary Line**: Maximum 72 characters. Capitalize first word after colon in lowercase or standard sentence case, no ending period.
- **Detailed Body**:
  - Separate header from body with an empty line.
  - Detail **what** was changed and **why**.
  - List bullet points detailing modified architectural layers (Domain, Data, Presentation), DI registrations, or i18n keys.

---

## 5. Commit Examples

### Example 1: Feature with Jira Ticket Scope
```text
feat(EXEMPLO-15): add custom bottom navigation bar and home tab layout

- Implemented VinumBottomNavigationBar with animated tab selection and floating action button.
- Extracted Explore, Cellar, and Collections tabs into independent Clean Architecture features.
- Integrated PopScope to ensure back navigation always redirects to Home tab.
- Added i18n keys for navigation items in pt_BR.json and en_US.json.
```

### Example 2: Bug Fix with Ticket Scope
```text
fix(VIN-42): persist auth tokens in secure storage to prevent session loss

- Migrated token persistence from SharedPreferences to FlutterSecureStorage.
- Encrypted access_token and refresh_token storage using hardware-backed KeyStore/Keychain.
- Added automatic session restoration on app startup and secure cleanup on logout.
```

### Example 3: Chore without Ticket
```text
chore(melos): configure Melos v8 monorepo workspace and scripts

- Added workspace configuration to pubspec.yaml for packages/essentials.
- Defined Melos scripts for bootstrap, format, analyze, build_runner, and test.
```
