import 'package:essentials/essentials.dart';
import 'package:flutter/material.dart';

import 'core/navigation/application_route.dart';
import 'feature/home/presentation/page/home_page.dart';
import 'feature/settings/presentation/page/settings_page.dart';

class VinumApp extends StatelessWidget {
  const VinumApp({super.key});

  static const List<Locale> supportedLocales = [
    Locale('pt', 'BR'),
    Locale('en', 'US'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = VinumTheme(VinumPalette());

    return MaterialApp(
      title: 'Vinum',
      debugShowCheckedModeBanner: false,
      theme: theme.themeData,
      localizationsDelegates: [
        const AppLocalizationDelegate(supportedLocales: supportedLocales),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: supportedLocales,
      locale: const Locale('pt', 'BR'),
      initialRoute: ApplicationRoute.home,
      routes: {
        ApplicationRoute.home: (_) => const HomePage(),
        ApplicationRoute.settings: (_) => const SettingsPage(),
      },
    );
  }
}
