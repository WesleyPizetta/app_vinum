import 'package:flutter/material.dart';

import 'color_palette.dart';

/// Paleta Escura — tons de preto, cinza escuro e destaques em dourado e rose.
class VinumDarkPalette implements ColorPalette {
  // ── Primárias (Dourado de destaque / Rose) ──
  @override
  Color get primary => const Color(0xFFDDA84F);

  @override
  Color get primaryLight => const Color(0xFFEAC47E);

  @override
  Color get primaryDark => const Color(0xFFBD5A6A);

  // ── Secundárias (Rose Art Nouveau) ──
  @override
  Color get secondary => const Color(0xFFBD5A6A);

  @override
  Color get secondaryLight => const Color(0xFFD48994);

  @override
  Color get secondaryDark => const Color(0xFF821C2E);

  // ── Superfícies ──
  @override
  Color get background => const Color(0xFF121212);

  @override
  Color get surface => const Color(0xFF1E1E1E);

  @override
  Color get error => const Color(0xFFCF6679);

  // ── On‑colors ──
  @override
  Color get onPrimary => const Color(0xFF121212);

  @override
  Color get onSecondary => const Color(0xFFF7F2E6);

  @override
  Color get onBackground => const Color(0xFFEDE2C6);

  @override
  Color get onSurface => const Color(0xFFEDE2C6);

  @override
  Color get onError => const Color(0xFF121212);

  // ── Utilitárias ──
  @override
  Color get divider => const Color(0xFF2C2C2C);

  @override
  Color get textPrimary => const Color(0xFFF7F2E6);

  @override
  Color get textSecondary => const Color(0xFFB5AF96);

  @override
  Color get textHint => const Color(0xFF75705C);

  @override
  Color get success => const Color(0xFF81C784);

  @override
  Color get warning => const Color(0xFFDDA84F);
}
