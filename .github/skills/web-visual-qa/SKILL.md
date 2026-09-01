---
name: web-visual-qa
description: "Perform web-based visual QA, UI inspection, and screenshot testing using browser tools. Use when: inspecting web UI layouts, validating Flutter Web or web app visual quality, taking screenshots of UI components, checking visual regressions, testing responsive breakpoints, or verifying interactive UI flows."
---

# Web Visual QA & Screenshot Testing Workflow

Use this skill when inspecting, testing, and visually validating web pages or Flutter Web applications using integrated browser tools.

---

## Workflow Steps

Follow this 4-step sequence for visual QA:

```text
1. Launch & Navigate ──► 2. Capture & Snapshot ──► 3. Inspect & Interact ──► 4. Report & Fix
   open_browser_page        screenshot_page          read_page / click_element    Structured Findings
                            or element snapshot      type_in_page                 & Code Fixes
```

### Step 1: Open Target Web Page
- Use browser tools to navigate to the target local or remote URL (e.g. `http://localhost:8080`, `file:///...`, or deployed staging URL).
- If testing responsive layouts, verify behavior at different viewport widths.

### Step 2: Capture Visual Baseline (Screenshot)
- Take a screenshot of the entire page or specific component elements to record visual state.
- Compare rendered output against expected design specifications, color palettes (`VinumPalette`), and spacing rules (`Dimens`).

### Step 3: Inspect & Interact (DOM & Accessibility Snapshot)
- Retrieve page DOM/accessibility snapshot to verify element text, accessibility labels, and element references.
- Test interactive flows (button clicks, form inputs, modal dialogs) using browser interaction tools.
- Capture post-interaction screenshots to verify state transitions (loading spinners, error banners, success modals).

### Step 4: Report Findings & Apply Fixes
- Document visual discrepancies clearly with file/line links to the corresponding Flutter widgets or Web templates.
- Apply layout fixes (favoring linear flex layouts `Column`/`Row` over fixed positioning) and re-verify visually.

---

## Visual QA Checklist

- [ ] **Layout & Alignment**: Elements align cleanly without unexpected wrapping, overflow badges, or overlapping text.
- [ ] **Responsiveness**: Layout adapts gracefully across mobile, tablet, and desktop viewports.
- [ ] **Design System Fidelity**: Spacing, radii, and colors match system tokens (`Dimens`, `VinumPalette`, `Theme.of(context)`).
- [ ] **Interactive States**: Buttons, inputs, hover states, and focus indicators render correctly when interacted with.
- [ ] **State Feedback**: Loading indicators, empty states, and error alerts appear in the expected locations without breaking layout flow.

---

## Visual QA Report Template

When delivering visual QA results, structure the report as follows:

```markdown
## Visual QA Summary
- **Target URL / View**: `[URL or Page Name]`
- **Status**: ✅ Passed / ⚠️ Discrepancies Found

### 📷 Captured Artifacts
- **Baseline Screenshot**: [Description or reference]
- **State Tested**: [Initial / After Form Submission / Error State]

### 🔴 Visual Issues Found
1. **[Component Name]**: [Description of misalignment, overflow, or color discrepancy]
   - **Expected**: [Design spec expectation]
   - **Actual**: [Observed rendered behavior]
   - **Widget / File**: [lib/path/file.dart#L30](lib/path/file.dart#L30)

### 📋 Fix Recommendations
- Convert fixed offsets to `Column` / `Row` with `Dimens` spacing.
- Ensure text overflow is handled (`TextOverflow.ellipsis`).
```
