import 'package:flutter/material.dart';

import 'color_palette.dart';

/// Paleta Art Nouveau — tons aquarelados, florais e delicados.
///
/// Cores do Style Guide:
/// - Rose (#BD5A6A)  — primária
/// - Burgundy (#821C2E) — primária escura
/// - Olive (#494729) — acento/texto
/// - Cream (#EDE2C6) — fundo
/// - Gold (#DDA84F) — secundária
class VinumPalette implements ColorPalette {
  // ── Primárias (Rose / Burgundy) ──
  @override
  Color get primary => const Color(0xFFBD5A6A);
  @override
  Color get primaryLight => const Color(0xFFD48994);
  @override
  Color get primaryDark => const Color(0xFF821C2E);

  // ── Secundárias (Gold) ──
  @override
  Color get secondary => const Color(0xFFDDA84F);
  @override
  Color get secondaryLight => const Color(0xFFEAC47E);
  @override
  Color get secondaryDark => const Color(0xFFC08B2D);

  // ── Superfícies ──
  @override
  Color get background => const Color(0xFFEDE2C6);
  @override
  Color get surface => const Color(0xFFF7F2E6);
  @override
  Color get error => const Color(0xFF9B2335);

  // ── On‑colors ──
  @override
  Color get onPrimary => const Color(0xFFF7F2E6);
  @override
  Color get onSecondary => const Color(0xFF494729);
  @override
  Color get onBackground => const Color(0xFF494729);
  @override
  Color get onSurface => const Color(0xFF494729);
  @override
  Color get onError => const Color(0xFFF7F2E6);

  // ── Utilitárias ──
  @override
  Color get divider => const Color(0xFFD5CBAD);
  @override
  Color get textPrimary => const Color(0xFF494729);
  @override
  Color get textSecondary => const Color(0xFF7A7558);
  @override
  Color get textHint => const Color(0xFFA49E80);
  @override
  Color get success => const Color(0xFF5C7A3B);
  @override
  Color get warning => const Color(0xFFDDA84F);
}
