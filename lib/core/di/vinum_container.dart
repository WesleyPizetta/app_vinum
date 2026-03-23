import 'package:essentials/essentials.dart';

import '../../feature/auth/data/api/auth_api_service.dart';
import '../../feature/auth/data/repository/auth_repository_impl.dart';
import '../../feature/auth/domain/repository/auth_repository.dart';
import '../../feature/auth/domain/usecase/sign_in.dart';
import '../../feature/auth/domain/usecase/sign_up.dart';
import '../../feature/auth/presentation/bloc/login_bloc.dart';
import '../../feature/auth/presentation/bloc/register_bloc.dart';
import '../../feature/home/presentation/bloc/home_bloc.dart';
import '../../feature/wine/data/datasource/wine_datasource.dart';
import '../../feature/wine/data/datasource/wine_mock_datasource.dart';
import '../../feature/wine/data/repository/wine_repository_impl.dart';
import '../../feature/wine/domain/repository/wine_repository.dart';
import '../../feature/wine/domain/usecase/get_wine_by_id.dart';
import '../../feature/wine/domain/usecase/get_wines.dart';
import '../../feature/wine/presentation/bloc/wine_detail_bloc.dart';
import '../../feature/wine/presentation/bloc/wine_list_bloc.dart';

// TODO: Descomentar quando a API real estiver disponível
// import '../../feature/wine/data/api/wine_api_service.dart';
// import '../../feature/wine/data/datasource/wine_remote_datasource.dart';

class VinumContainer {
  static void setup() {
    // ── Chopper HTTP Client (BFF) ──
    ApplicationContainer.registerLazySingleton<ChopperClient>(
      () => createChopperClient(
        baseUrl: ApplicationContainer.resolve<Environment>().apiUrl,
        services: [
          AuthApiService.create(),
          // WineApiService.create(), // descomentar quando API real estiver pronta
        ],
      ),
    );

    // ── API Services (Chopper) ──
    ApplicationContainer.registerLazySingleton<AuthApiService>(
      () => ApplicationContainer.resolve<ChopperClient>()
          .getService<AuthApiService>(),
    );

    // ── Auth ──
    ApplicationContainer.registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(
        authService: ApplicationContainer.resolve<AuthApiService>(),
      ),
    );
    ApplicationContainer.registerLazySingleton<SignIn>(
      () => SignIn(ApplicationContainer.resolve<AuthRepository>()),
    );
    ApplicationContainer.registerLazySingleton<SignUp>(
      () => SignUp(ApplicationContainer.resolve<AuthRepository>()),
    );
    ApplicationContainer.registerFactory<LoginBloc>(
      () => LoginBloc(
        ApplicationContainer.resolve<SignIn>(),
        ApplicationContainer.resolve<AuthRepository>(),
      ),
    );
    ApplicationContainer.registerFactory<RegisterBloc>(
      () => RegisterBloc(ApplicationContainer.resolve<SignUp>()),
    );

    // ── Chopper WineApiService ──
    // TODO: Descomentar quando a API real estiver disponível
    // ApplicationContainer.registerLazySingleton<WineApiService>(
    //   () => ApplicationContainer.resolve<ChopperClient>()
    //       .getService<WineApiService>(),
    // );

    // ── Datasources ──
    // TODO: Trocar WineMockDatasource por WineRemoteDatasource para dados reais:
    // ApplicationContainer.registerLazySingleton<WineDatasource>(
    //   () => WineRemoteDatasource(ApplicationContainer.resolve<WineApiService>()),
    // );
    ApplicationContainer.registerLazySingleton<WineDatasource>(
      () => WineMockDatasource(),
    );

    // ── Repositories ──
    ApplicationContainer.registerLazySingleton<WineRepository>(
      () => WineRepositoryImpl(ApplicationContainer.resolve<WineDatasource>()),
    );

    // ── UseCases ──
    ApplicationContainer.registerLazySingleton<GetWines>(
      () => GetWines(ApplicationContainer.resolve<WineRepository>()),
    );
    ApplicationContainer.registerLazySingleton<GetWineById>(
      () => GetWineById(ApplicationContainer.resolve<WineRepository>()),
    );

    // ── BLoCs ──
    ApplicationContainer.registerFactory<HomeBloc>(() => HomeBloc());
    ApplicationContainer.registerFactory<WineListBloc>(
      () => WineListBloc(ApplicationContainer.resolve<GetWines>()),
    );
    ApplicationContainer.registerFactory<WineDetailBloc>(
      () => WineDetailBloc(ApplicationContainer.resolve<GetWineById>()),
    );
  }
}
