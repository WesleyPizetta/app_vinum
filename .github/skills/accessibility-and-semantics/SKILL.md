---
name: accessibility-and-semantics
description: "Audit, implement, and test accessibility (a11y) and Flutter Semantics for inclusive UX. Use when: adding Semantics widgets, auditing screen readers (TalkBack/VoiceOver), checking tap target sizes, verifying text contrast, or testing accessibility bounds."
---

# Accessibility (a11y) and Semantics Guidelines for app_vinum

Use this skill when implementing, auditing, or refactoring UI components to ensure compliance with accessibility standards and screen reader support (TalkBack & VoiceOver).

---

## 1. Core Principles

- **Every interactive element must have a label**: Buttons, icon-only actions, and touchable surfaces must convey their purpose to screen readers.
- **Minimum Tap Target**: Interactive controls must have a touch target of at least **48x48 dp**.
- **Sufficient Color Contrast**: Text and icons must meet WCAG AA contrast ratio standards against backgrounds (`VinumPalette`).
- **Scalable Typography**: Text widgets must support system font scaling without clipping or overflowing layout containers.

---

## 2. Using `Semantics` & `MergeSemantics`

### Example A: Icon Button with Semantic Label
```dart
// ALWAYS wrap icon-only buttons with explicit Semantics or tooltip
Semantics(
  button: true,
  label: 'Filtrar vinhos',
  hint: 'Abre a tela de filtros de pesquisa',
  child: IconButton(
    icon: const Icon(Icons.filter_list, size: Dimens.iconMedium),
    onPressed: () => _openFilterModal(context),
  ),
)
```

### Example B: Merging Complex Card Information
When a card has multiple text labels that belong together, merge them so screen readers announce them as a single logical unit:

```dart
// Merge card children so TalkBack reads: "Château Margaux, safra 2018, avaliação 4.8 de 5"
MergeSemantics(
  child: Card(
    child: Padding(
      padding: const EdgeInsets.all(Dimens.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(wine.name, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: Dimens.spacing4),
          Text('Safra ${wine.vintage}', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: Dimens.spacing8),
          Semantics(
            label: 'Avaliação ${wine.rating} de 5 estrelas',
            excludeSemantics: true, // Hides raw text "4.8" from duplicate reading
            child: RatingBar(rating: wine.rating),
          ),
        ],
      ),
    ),
  ),
)
```

---

## 3. Accessibility Testing in Widget Tests

Verify semantic nodes in automated widget tests:

```dart
testWidgets('IconButton has correct accessibility semantics', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Semantics(
          button: true,
          label: 'Filtrar vinhos',
          child: IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {},
          ),
        ),
      ),
    ),
  );

  // Verify semantic node is present in the tree
  expect(
    tester.getSemantics(find.byType(IconButton)),
    matchesSemantics(
      isButton: true,
      label: 'Filtrar vinhos',
      hasTapAction: true,
    ),
  );
});
```

---

## 4. Accessibility Review Checklist

- [ ] **Icon Buttons**: Icon-only buttons have explicit `Semantics(label: ...)` or `Tooltip`.
- [ ] **Touch Targets**: Buttons and touchable areas are at least 48x48 dp (use `Dimens.iconMedium` + padding or `InkWell`).
- [ ] **Screen Reader Flow**: Cards and complex list items use `MergeSemantics` where appropriate.
- [ ] **Decorations & Images**: Decorative icons/images have `excludeSemantics: true` or `Semantics(container: false)` so they don't clutter screen reader announcements.
- [ ] **Contrast**: Text colors from `VinumPalette` maintain high contrast against `background` (`#EDE2C6`) and `surface` (`#F7F2E6`).
- [ ] **Text Scale**: Text containers handle large font scaling gracefully using `SingleChildScrollView` or `Flexible`.
