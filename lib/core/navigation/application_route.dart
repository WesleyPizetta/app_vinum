class ApplicationRoute {
  ApplicationRoute._();

  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/';
  static const String onboarding = '/onboarding';

  /// "Como você quer ser chamado?" (apelido). `arguments`: `NicknameArgs`.
  static const String nickname = '/nickname';
  static const String settings = '/settings';
  static const String wineList = '/wines';
  static const String wineDetail = '/wines/detail';

  /// Vinhos por categoria de comida. `arguments`: `FoodCategory`.
  static const String foodWines = '/wines/food';
  static const String me = '/me';
}
