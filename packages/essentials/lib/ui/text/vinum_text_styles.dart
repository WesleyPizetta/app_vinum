import 'package:flutter/material.dart';

/// Fontes do Vinum:
///
/// | Fonte        | Papel                          |
/// |--------------|--------------------------------|
/// | Amarante     | Display, Headline, Title, Body |
/// | Caveat       | Labels / Destaques pontuais    |
class VinumTextStyles {
  static const String amarante = 'Amarante';
  static const String caveat = 'Caveat';

  static TextTheme textTheme(Color primaryColor, Color secondaryColor) {
    return TextTheme(
      // ── Display (Amarante) ──
      displayLarge: _style(34, FontWeight.bold, primaryColor, amarante),
      displayMedium: _style(28, FontWeight.bold, primaryColor, amarante),
      displaySmall: _style(24, FontWeight.bold, primaryColor, amarante),

      // ── Headline (Amarante, peso maior) ──
      headlineLarge: _style(24, FontWeight.w700, primaryColor, amarante),
      headlineMedium: _style(20, FontWeight.w700, primaryColor, amarante),
      headlineSmall: _style(18, FontWeight.w600, primaryColor, amarante),

      // ── Title (Amarante) ──
      titleLarge: _style(20, FontWeight.w600, primaryColor, amarante),
      titleMedium: _style(16, FontWeight.w500, primaryColor, amarante),
      titleSmall: _style(14, FontWeight.w500, primaryColor, amarante),

      // ── Body (Amarante) ──
      bodyLarge: _style(16, FontWeight.normal, primaryColor, amarante),
      bodyMedium: _style(14, FontWeight.normal, primaryColor, amarante),
      bodySmall: _style(12, FontWeight.normal, secondaryColor, amarante),

      // ── Label (Caveat — manuscrito, aquarelado) ──
      labelLarge: _style(14, FontWeight.w600, primaryColor, caveat),
      labelMedium: _style(12, FontWeight.w500, primaryColor, caveat),
      labelSmall: _style(10, FontWeight.w500, secondaryColor, caveat),
    );
  }

  static TextStyle _style(
    double size,
    FontWeight weight,
    Color color,
    String fontFamily,
  ) {
    return TextStyle(
      fontSize: size,
      fontWeight: weight,
      color: color,
      fontFamily: fontFamily,
    );
  }
}
