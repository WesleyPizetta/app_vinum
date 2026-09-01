import 'package:essentials/essentials.dart';

import '../../feature/auth/data/api/auth_api_service.dart';
import '../../feature/auth/data/repository/auth_repository_impl.dart';
import '../../feature/auth/domain/repository/auth_repository.dart';
import '../../feature/auth/domain/usecase/sign_in.dart';
import '../../feature/auth/domain/usecase/sign_up.dart';
import '../../feature/auth/domain/usecase/logout.dart';
import '../../feature/auth/presentation/bloc/login_bloc.dart';
import '../../feature/auth/presentation/bloc/register_bloc.dart';
import '../../feature/home/presentation/bloc/home_bloc.dart';
import '../../feature/profile/data/api/profile_api_service.dart';
import '../../feature/profile/presentation/bloc/profile_bloc.dart';
import '../../feature/wine/data/datasource/wine_datasource.dart';
import '../../feature/wine/data/datasource/wine_mock_datasource.dart';
import '../../feature/wine/data/repository/wine_repository_impl.dart';
import '../../feature/wine/domain/repository/wine_repository.dart';
import '../../feature/wine/domain/usecase/get_wine_by_id.dart';
import '../../feature/wine/domain/usecase/get_wines.dart';
import '../../feature/wine/presentation/bloc/wine_detail_bloc.dart';
import '../../feature/wine/presentation/bloc/wine_list_bloc.dart';
import '../../feature/review/data/api/review_api_service.dart';
import '../../feature/review/data/datasource/review_datasource.dart';
import '../../feature/review/data/datasource/review_remote_datasource.dart';
import '../../feature/review/data/repository/review_repository_impl.dart';
import '../../feature/review/domain/repository/review_repository.dart';
import '../../feature/review/domain/usecase/get_wine_reviews.dart';
import '../../feature/review/domain/usecase/get_review_tags.dart';
import '../../feature/review/domain/usecase/create_review.dart';
import '../../feature/review/domain/usecase/update_review.dart';
import '../../feature/review/domain/usecase/delete_review.dart';
import '../../feature/review/presentation/bloc/review_list_bloc.dart';
import '../../feature/review/presentation/bloc/review_form_bloc.dart';
import '../../feature/explore/data/datasource/explore_datasource.dart';
import '../../feature/explore/data/datasource/explore_mock_datasource.dart';
import '../../feature/explore/data/repository/explore_repository_impl.dart';
import '../../feature/explore/domain/repository/explore_repository.dart';
import '../../feature/explore/domain/usecase/get_explore_items.dart';
import '../../feature/explore/presentation/bloc/explore_bloc.dart';
import '../../feature/cellar/data/datasource/cellar_datasource.dart';
import '../../feature/cellar/data/datasource/cellar_mock_datasource.dart';
import '../../feature/cellar/data/repository/cellar_repository_impl.dart';
import '../../feature/cellar/domain/repository/cellar_repository.dart';
import '../../feature/cellar/domain/usecase/get_cellar_items.dart';
import '../../feature/cellar/presentation/bloc/cellar_bloc.dart';
import '../../feature/collections/data/datasource/collections_datasource.dart';
import '../../feature/collections/data/datasource/collections_mock_datasource.dart';
import '../../feature/collections/data/repository/collections_repository_impl.dart';
import '../../feature/collections/domain/repository/collections_repository.dart';
import '../../feature/collections/domain/usecase/get_collections.dart';
import '../../feature/collections/presentation/bloc/collections_bloc.dart';
import '../../feature/settings/data/datasource/settings_datasource.dart';
import '../../feature/settings/data/datasource/settings_local_datasource.dart';
import '../../feature/settings/data/repository/settings_repository_impl.dart';
import '../../feature/settings/domain/repository/settings_repository.dart';
import '../../feature/settings/domain/usecase/get_theme_mode.dart';
import '../../feature/settings/domain/usecase/set_theme_mode.dart';
import '../../feature/settings/presentation/bloc/settings_bloc.dart';

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
          ReviewApiService.create(),
          ProfileApiService.create(),
          // WineApiService.create(), // descomentar quando API real estiver pronta
        ],
        interceptors: [
          AuthHeaderInterceptor(
            () => ApplicationContainer.resolve<AuthRepository>().getAccessToken(),
          ),
        ],
      ),
    );

    // ── API Services (Chopper) ──
    ApplicationContainer.registerLazySingleton<AuthApiService>(
      () => ApplicationContainer.resolve<ChopperClient>()
          .getService<AuthApiService>(),
    );
    ApplicationContainer.registerLazySingleton<ProfileApiService>(
      () => ApplicationContainer.resolve<ChopperClient>()
          .getService<ProfileApiService>(),
    );

    // ── Auth ──
    ApplicationContainer.registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(
        authService: ApplicationContainer.resolve<AuthApiService>(),
        profileService: ApplicationContainer.resolve<ProfileApiService>(),
      ),
    );
    ApplicationContainer.registerLazySingleton<SignIn>(
      () => SignIn(ApplicationContainer.resolve<AuthRepository>()),
    );
    ApplicationContainer.registerLazySingleton<SignUp>(
      () => SignUp(ApplicationContainer.resolve<AuthRepository>()),
    );
    ApplicationContainer.registerLazySingleton<Logout>(
      () => Logout(ApplicationContainer.resolve<AuthRepository>()),
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
    ApplicationContainer.registerFactory<ProfileBloc>(
      () => ProfileBloc(
        ApplicationContainer.resolve<AuthRepository>(),
        ApplicationContainer.resolve<Logout>(),
      ),
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

    // ── Reviews ──
    ApplicationContainer.registerLazySingleton<ReviewApiService>(
      () => ApplicationContainer.resolve<ChopperClient>()
          .getService<ReviewApiService>(),
    );
    ApplicationContainer.registerLazySingleton<ReviewDatasource>(
      () => ReviewRemoteDatasource(
          ApplicationContainer.resolve<ReviewApiService>()),
    );
    ApplicationContainer.registerLazySingleton<ReviewRepository>(
      () => ReviewRepositoryImpl(
          ApplicationContainer.resolve<ReviewDatasource>()),
    );
    ApplicationContainer.registerLazySingleton<GetWineReviews>(
      () => GetWineReviews(ApplicationContainer.resolve<ReviewRepository>()),
    );
    ApplicationContainer.registerLazySingleton<GetReviewTags>(
      () => GetReviewTags(ApplicationContainer.resolve<ReviewRepository>()),
    );
    ApplicationContainer.registerLazySingleton<CreateReview>(
      () => CreateReview(ApplicationContainer.resolve<ReviewRepository>()),
    );
    ApplicationContainer.registerLazySingleton<UpdateReview>(
      () => UpdateReview(ApplicationContainer.resolve<ReviewRepository>()),
    );
    ApplicationContainer.registerLazySingleton<DeleteReview>(
      () => DeleteReview(ApplicationContainer.resolve<ReviewRepository>()),
    );

    // ── BLoCs ──
    ApplicationContainer.registerFactory<HomeBloc>(
      () => HomeBloc(ApplicationContainer.resolve<AuthRepository>()),
    );
    ApplicationContainer.registerFactory<WineListBloc>(
      () => WineListBloc(ApplicationContainer.resolve<GetWines>()),
    );
    ApplicationContainer.registerFactory<WineDetailBloc>(
      () => WineDetailBloc(ApplicationContainer.resolve<GetWineById>()),
    );
    ApplicationContainer.registerFactory<ReviewListBloc>(
      () => ReviewListBloc(ApplicationContainer.resolve<GetWineReviews>()),
    );
    ApplicationContainer.registerFactory<ReviewFormBloc>(
      () => ReviewFormBloc(
        ApplicationContainer.resolve<CreateReview>(),
        ApplicationContainer.resolve<UpdateReview>(),
        ApplicationContainer.resolve<DeleteReview>(),
        ApplicationContainer.resolve<GetReviewTags>(),
      ),
    );

    // ── Explore Feature ──
    ApplicationContainer.registerLazySingleton<ExploreDatasource>(
      () => ExploreMockDatasource(),
    );
    ApplicationContainer.registerLazySingleton<ExploreRepository>(
      () => ExploreRepositoryImpl(
        ApplicationContainer.resolve<ExploreDatasource>(),
      ),
    );
    ApplicationContainer.registerLazySingleton<GetExploreItems>(
      () => GetExploreItems(
        ApplicationContainer.resolve<ExploreRepository>(),
      ),
    );
    ApplicationContainer.registerFactory<ExploreBloc>(
      () => ExploreBloc(
        ApplicationContainer.resolve<GetExploreItems>(),
      ),
    );

    // ── Cellar Feature ──
    ApplicationContainer.registerLazySingleton<CellarDatasource>(
      () => CellarMockDatasource(),
    );
    ApplicationContainer.registerLazySingleton<CellarRepository>(
      () => CellarRepositoryImpl(
        ApplicationContainer.resolve<CellarDatasource>(),
      ),
    );
    ApplicationContainer.registerLazySingleton<GetCellarItems>(
      () => GetCellarItems(
        ApplicationContainer.resolve<CellarRepository>(),
      ),
    );
    ApplicationContainer.registerFactory<CellarBloc>(
      () => CellarBloc(
        ApplicationContainer.resolve<GetCellarItems>(),
      ),
    );

    // ── Collections Feature ──
    ApplicationContainer.registerLazySingleton<CollectionsDatasource>(
      () => CollectionsMockDatasource(),
    );
    ApplicationContainer.registerLazySingleton<CollectionsRepository>(
      () => CollectionsRepositoryImpl(
        ApplicationContainer.resolve<CollectionsDatasource>(),
      ),
    );
    ApplicationContainer.registerLazySingleton<GetCollections>(
      () => GetCollections(
        ApplicationContainer.resolve<CollectionsRepository>(),
      ),
    );
    ApplicationContainer.registerFactory<CollectionsBloc>(
      () => CollectionsBloc(
        ApplicationContainer.resolve<GetCollections>(),
      ),
    );

    // ── Settings & Theme Feature ──
    ApplicationContainer.registerLazySingleton<SettingsDatasource>(
      () => SettingsLocalDatasource(),
    );
    ApplicationContainer.registerLazySingleton<SettingsRepository>(
      () => SettingsRepositoryImpl(
        ApplicationContainer.resolve<SettingsDatasource>(),
      ),
    );
    ApplicationContainer.registerLazySingleton<GetThemeMode>(
      () => GetThemeMode(
        ApplicationContainer.resolve<SettingsRepository>(),
      ),
    );
    ApplicationContainer.registerLazySingleton<SetThemeMode>(
      () => SetThemeMode(
        ApplicationContainer.resolve<SettingsRepository>(),
      ),
    );
    ApplicationContainer.registerLazySingleton<SettingsBloc>(
      () => SettingsBloc(
        ApplicationContainer.resolve<GetThemeMode>(),
        ApplicationContainer.resolve<SetThemeMode>(),
      ),
    );
  }
}
