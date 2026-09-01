import 'package:flutter/material.dart';

/// Fontes do Vinum:
///
/// | Fonte        | Papel                                                      |
/// |--------------|------------------------------------------------------------|
/// | Amarante     | Display / Branding grande (destaques visuais e títulos)   |
/// | Sans-Serif   | Title, Body, Label, Buttons, Inputs (máxima legibilidade)  |
class VinumTextStyles {
  static const String amarante = 'Amarante';

  static TextTheme textTheme(Color primaryColor, Color secondaryColor) {
    return TextTheme(
      // ── Display / Títulos de Marca (Amarante - grandes dimensões) ──
      displayLarge: _style(34, FontWeight.bold, primaryColor, amarante),
      displayMedium: _style(28, FontWeight.bold, primaryColor, amarante),
      displaySmall: _style(24, FontWeight.bold, primaryColor, amarante),

      // ── Headline (Amarante em grandes, Sans-Serif em menores) ──
      headlineLarge: _style(24, FontWeight.w700, primaryColor, amarante),
      headlineMedium: _style(20, FontWeight.w700, primaryColor),
      headlineSmall: _style(18, FontWeight.w600, primaryColor),

      // ── Title (Sans-Serif para alta legibilidade) ──
      titleLarge: _style(20, FontWeight.w600, primaryColor),
      titleMedium: _style(16, FontWeight.w600, primaryColor),
      titleSmall: _style(14, FontWeight.w600, primaryColor),

      // ── Body (Sans-Serif - leitura contínua e acessível) ──
      bodyLarge: _style(16, FontWeight.normal, primaryColor),
      bodyMedium: _style(14, FontWeight.normal, primaryColor),
      bodySmall: _style(12, FontWeight.normal, secondaryColor),

      // ── Label (Sans-Serif - leitura rápida de botões e tags) ──
      labelLarge: _style(14, FontWeight.w600, primaryColor),
      labelMedium: _style(12, FontWeight.w600, primaryColor),
      labelSmall: _style(11, FontWeight.w500, secondaryColor),
    );
  }

  static TextStyle _style(
    double size,
    FontWeight weight,
    Color color, [
    String? fontFamily,
  ]) {
    return TextStyle(
      fontSize: size,
      fontWeight: weight,
      color: color,
      fontFamily: fontFamily,
    );
  }
}
