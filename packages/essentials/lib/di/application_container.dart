import 'package:get_it/get_it.dart';

class ApplicationContainer {
  static final GetIt _getIt = GetIt.instance;

  static T resolve<T extends Object>() => _getIt.get<T>();

  static void registerSingleton<T extends Object>(T instance) =>
      _getIt.registerSingleton<T>(instance);

  static void registerLazySingleton<T extends Object>(T Function() factory) =>
      _getIt.registerLazySingleton<T>(factory);

  static void registerFactory<T extends Object>(T Function() factory) =>
      _getIt.registerFactory<T>(factory);

  static bool isRegistered<T extends Object>() => _getIt.isRegistered<T>();

  static Future<void> reset() => _getIt.reset();
}
