---
name: flutter-flex-layout
description: "Guide Flutter UI implementations to prefer linear layout widgets (Column, Row, Flex, Wrap) over unnecessary Stack and Positioned usage. Use when: creating UI widgets, building Flutter pages, refactoring UI layouts, or positioning elements on screen."
---

# Flutter Flex Layout Best Practices (Column & Row First)

This skill enforces clean, maintainable, and responsive Flutter UI layouts by prioritizing standard linear flow (`Column`, `Row`, `Wrap`, `Flex`) over over-engineered `Stack` and `Positioned` configurations.

---

## Core Rule

> **Default to `Column` and `Row`. Use `Stack` ONLY for true visual overlays.**

- **Use `Column` / `Row`**: For any UI element that flows sequentially (top-to-bottom, left-to-right), even if it involves spacing, alignment, stretching, or flexible fill.
- **Use `Stack` + `Positioned` ONLY when**: One element must physically float on top of another (e.g. notification badge on an avatar, close button over a image header, background image with overlaid text).

---

## Decision Matrix: How to Layout Elements

| UI Need | DO THIS (`Column`/`Row`) | DO NOT DO THIS (`Stack`/`Positioned`) |
|---|---|---|
| Vertically stacked widgets | `Column(children: [...])` | `Stack` with `Positioned(top: 0)`, `Positioned(top: 50)` |
| Horizontally aligned widgets | `Row(children: [...])` | `Stack` with `Positioned(left: 0)`, `Positioned(left: 100)` |
| Pushing a widget to the bottom/end | `Column(children: [..., Spacer(), BottomButton()])` | `Stack` with `Positioned(bottom: 0)` |
| Expanding a child to fill space | `Expanded(child: ListView(...))` | `Stack` with `Positioned.fill(...)` |
| Spacing between items | `SizedBox(height: Dimens.spacing16)` or `Padding` | `Positioned(top: 120)` offsets |
| Centering elements | `MainAxisAlignment.center` / `CrossAxisAlignment.center` | `Positioned(left: MediaQuery.of(context).size.width / 4)` |

---

## Code Comparison Examples

### Example 1: Form Fields & Submit Button

❌ **BAD (Unnecessary Stack & Positioned)**:
```dart
// DO NOT DO THIS — Fragile, overflows on small screens, hard to maintain
Stack(
  children: [
    Positioned(
      top: 20,
      left: 16,
      right: 16,
      child: CustomTextField(label: 'Email'),
    ),
    Positioned(
      top: 90,
      left: 16,
      right: 16,
      child: CustomTextField(label: 'Password'),
    ),
    Positioned(
      bottom: 20,
      left: 16,
      right: 16,
      child: PrimaryButton(text: 'Submit'),
    ),
  ],
)
```

✅ **GOOD (Clean Column + Spacer/Expanded)**:
```dart
// DO THIS — Responsive, adapts to keyboard, safe layout
Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [
    const CustomTextField(label: 'Email'),
    const SizedBox(height: Dimens.spacing16),
    const CustomTextField(label: 'Password'),
    const Spacer(),
    PrimaryButton(text: 'Submit'),
  ],
)
```

---

### Example 2: Icon with Label and Subtitle

❌ **BAD (Stack with calculated offsets)**:
```dart
// DO NOT DO THIS
Stack(
  children: [
    Positioned(left: 0, top: 10, child: Icon(Icons.wine_bar)),
    Positioned(left: 40, top: 0, child: Text('Title', style: titleStyle)),
    Positioned(left: 40, top: 24, child: Text('Subtitle', style: subtitleStyle)),
  ],
)
```

✅ **GOOD (Row containing a Column)**:
```dart
// DO THIS
Row(
  children: [
    const Icon(Icons.wine_bar, size: Dimens.iconMedium),
    const SizedBox(width: Dimens.spacing12),
    Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Title', style: titleStyle),
          const SizedBox(height: Dimens.spacing4),
          Text('Subtitle', style: subtitleStyle),
        ],
      ),
    ),
  ],
)
```

---

## When `Stack` IS Legitimate

`Stack` is acceptable **only** when items overlap in 3D Z-index space:

```dart
// LEGITIMATE USE OF STACK: Badge overlapping top-right of Avatar
Stack(
  clipBehavior: Clip.none,
  children: [
    const CircleAvatar(radius: Dimens.spacing24),
    Positioned(
      right: 0,
      top: 0,
      child: NotificationBadge(),
    ),
  ],
)
```

---

## Checklist for Code Review

- [ ] Is `Stack` being used purely for vertical or horizontal sequence? → Convert to `Column` or `Row`.
- [ ] Are manual pixel offsets (`top: 120`, `left: 45`) used to position standard flow widgets? → Replace with `SizedBox(height/width)`, `Padding`, or `MainAxisAlignment`.
- [ ] Is `Positioned(bottom: 0)` used to pin a footer/button? → Use `Column` + `Spacer()` or `Expanded()`.
- [ ] Are design system spacing constants (`Dimens.spacing16`, etc.) used instead of hardcoded numbers?
