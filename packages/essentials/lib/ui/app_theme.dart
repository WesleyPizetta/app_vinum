import 'package:flutter/material.dart';

import 'colors/color_palette.dart';
import 'text/vinum_text_styles.dart';

class VinumTheme {
  final ColorPalette palette;

  VinumTheme(this.palette);

  ThemeData get themeData => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme(
          brightness: Brightness.light,
          primary: palette.primary,
          onPrimary: palette.onPrimary,
          secondary: palette.secondary,
          onSecondary: palette.onSecondary,
          error: palette.error,
          onError: palette.onError,
          surface: palette.surface,
          onSurface: palette.onSurface,
        ),
        scaffoldBackgroundColor: palette.background,
        dividerColor: palette.divider,
        textTheme: VinumTextStyles.textTheme(
          palette.textPrimary,
          palette.textSecondary,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: palette.primaryDark,
          foregroundColor: palette.onPrimary,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontFamily: 'Amarante',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: palette.onPrimary,
          ),
        ),
        cardTheme: CardThemeData(
          color: palette.surface,
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: palette.primary,
            foregroundColor: palette.onPrimary,
            textStyle: const TextStyle(
              fontFamily: 'Amarante',
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            elevation: 0,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: palette.primary,
            side: BorderSide(color: palette.primary, width: 1.5),
            textStyle: const TextStyle(
              fontFamily: 'Amarante',
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: palette.secondary,
          foregroundColor: palette.onSecondary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: palette.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: palette.divider),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: palette.divider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: palette.primary, width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: palette.surface,
          selectedColor: palette.primary.withAlpha(30),
          side: BorderSide(color: palette.divider),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: palette.surface,
          selectedItemColor: palette.primaryDark,
          unselectedItemColor: palette.textHint,
        ),
      );
}
