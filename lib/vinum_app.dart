import 'package:essentials/essentials.dart';
import 'package:flutter/material.dart';

import 'core/navigation/application_route.dart';
import 'feature/auth/presentation/page/login_page.dart';
import 'feature/auth/presentation/page/register_page.dart';
import 'feature/home/presentation/page/home_page.dart';
import 'feature/settings/presentation/page/settings_page.dart';
import 'feature/profile/presentation/page/profile_page.dart';
import 'feature/wine/presentation/page/wine_detail_page.dart';
import 'feature/wine/presentation/page/wine_list_page.dart';

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
      initialRoute: ApplicationRoute.login,
      routes: {
        ApplicationRoute.login: (_) => const LoginPage(),
        ApplicationRoute.register: (_) => const RegisterPage(),
        ApplicationRoute.home: (_) => const HomePage(),
        ApplicationRoute.settings: (_) => const SettingsPage(),
        ApplicationRoute.wineList: (_) => const WineListPage(),
        ApplicationRoute.wineDetail: (_) => const WineDetailPage(),
        ApplicationRoute.me: (_) => const ProfilePage(),
      },
    );
  }
}
