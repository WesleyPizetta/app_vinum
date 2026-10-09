import 'package:essentials/essentials.dart';

import '../../feature/auth/data/api/auth_api_service.dart';
import '../../feature/auth/data/repository/auth_repository_impl.dart';
import '../../feature/auth/domain/repository/auth_repository.dart';
import '../../feature/auth/domain/usecase/get_onboarding_quiz.dart';
import '../../feature/auth/domain/usecase/sign_in.dart';
import '../../feature/auth/domain/usecase/submit_onboarding_quiz.dart';
import '../../feature/auth/domain/usecase/sign_up.dart';
import '../../feature/auth/domain/usecase/logout.dart';
import '../../feature/auth/presentation/bloc/login_bloc.dart';
import '../../feature/auth/presentation/bloc/onboarding_bloc.dart';
import '../../feature/auth/presentation/bloc/register_bloc.dart';
import '../../feature/favorites/data/api/favorite_api_service.dart';
import '../../feature/favorites/data/repository/favorites_repository_impl.dart';
import '../../feature/favorites/domain/repository/favorites_repository.dart';
import '../../feature/favorites/domain/usecase/get_favorites.dart';
import '../../feature/favorites/domain/usecase/load_favorite_ids.dart';
import '../../feature/favorites/domain/usecase/set_favorite.dart';
import '../../feature/favorites/domain/usecase/watch_favorite_ids.dart';
import '../../feature/favorites/presentation/bloc/favorites_list_bloc.dart';
import '../../feature/favorites/presentation/bloc/wine_favorite_bloc.dart';
import '../../feature/home/data/api/recommendation_api_service.dart';
import '../../feature/home/data/repository/recommendation_repository_impl.dart';
import '../../feature/home/domain/repository/recommendation_repository.dart';
import '../../feature/home/domain/usecase/get_food_recommendations.dart';
import '../../feature/home/domain/usecase/get_recommendations.dart';
import '../../feature/home/domain/usecase/get_wine_match.dart';
import '../../feature/home/domain/usecase/search_wines.dart';
import '../../feature/home/presentation/bloc/food_wines_bloc.dart';
import '../../feature/home/presentation/bloc/home_bloc.dart';
import '../../feature/home/presentation/bloc/search_bloc.dart';
import '../../feature/profile/data/api/profile_api_service.dart';
import '../../feature/profile/presentation/bloc/profile_bloc.dart';
import '../../feature/wine/data/datasource/wine_datasource.dart';
import '../../feature/wine/data/api/wine_api_service.dart';
import '../../feature/wine/data/datasource/wine_remote_datasource.dart';
import '../../feature/wine/data/repository/wine_repository_impl.dart';
import '../../feature/wine/domain/repository/wine_repository.dart';
import '../../feature/wine/domain/usecase/get_wine_by_id.dart';
import '../../feature/wine/domain/usecase/get_wine_highlights.dart';
import '../../feature/wine/domain/usecase/get_wines.dart';
import '../../feature/wine/presentation/bloc/wine_detail_bloc.dart';
import '../../feature/wine/presentation/bloc/wine_list_bloc.dart';
import '../../feature/wine/presentation/bloc/wine_match_bloc.dart';
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
import '../../feature/cellar/data/api/cellar_api_service.dart';
import '../../feature/cellar/data/repository/cellar_repository_impl.dart';
import '../../feature/cellar/domain/repository/cellar_repository.dart';
import '../../feature/cellar/domain/usecase/get_my_reviews.dart';
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
          RecommendationApiService.create(),
          WineApiService.create(),
          FavoriteApiService.create(),
          CellarApiService.create(),
        ],
        interceptors: [
          AuthHeaderInterceptor(
            () =>
                ApplicationContainer.resolve<AuthRepository>().getAccessToken(),
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
    ApplicationContainer.registerLazySingleton<RecommendationApiService>(
      () => ApplicationContainer.resolve<ChopperClient>()
          .getService<RecommendationApiService>(),
    );
    ApplicationContainer.registerLazySingleton<FavoriteApiService>(
      () => ApplicationContainer.resolve<ChopperClient>()
          .getService<FavoriteApiService>(),
    );
    ApplicationContainer.registerLazySingleton<CellarApiService>(
      () => ApplicationContainer.resolve<ChopperClient>()
          .getService<CellarApiService>(),
    );

    // ── Favoritos (cache em memória compartilhado entre as telas) ──
    ApplicationContainer.registerLazySingleton<FavoritesRepository>(
      () => FavoritesRepositoryImpl(
        ApplicationContainer.resolve<FavoriteApiService>(),
      ),
    );
    ApplicationContainer.registerLazySingleton<LoadFavoriteIds>(
      () =>
          LoadFavoriteIds(ApplicationContainer.resolve<FavoritesRepository>()),
    );
    ApplicationContainer.registerLazySingleton<SetFavorite>(
      () => SetFavorite(ApplicationContainer.resolve<FavoritesRepository>()),
    );
    ApplicationContainer.registerLazySingleton<GetFavorites>(
      () => GetFavorites(ApplicationContainer.resolve<FavoritesRepository>()),
    );
    ApplicationContainer.registerLazySingleton<WatchFavoriteIds>(
      () =>
          WatchFavoriteIds(ApplicationContainer.resolve<FavoritesRepository>()),
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
      () => Logout(
        ApplicationContainer.resolve<AuthRepository>(),
        // Caches da sessão limpos a cada logout (inclui sessão expirada).
        [ApplicationContainer.resolve<FavoritesRepository>()],
      ),
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
    ApplicationContainer.registerLazySingleton<GetOnboardingQuiz>(
      () => GetOnboardingQuiz(ApplicationContainer.resolve<AuthRepository>()),
    );
    ApplicationContainer.registerLazySingleton<SubmitOnboardingQuiz>(
      () => SubmitOnboardingQuiz(
        ApplicationContainer.resolve<AuthRepository>(),
      ),
    );
    ApplicationContainer.registerFactory<OnboardingBloc>(
      () => OnboardingBloc(
        ApplicationContainer.resolve<GetOnboardingQuiz>(),
        ApplicationContainer.resolve<SubmitOnboardingQuiz>(),
        ApplicationContainer.resolve<Logout>(),
      ),
    );
    ApplicationContainer.registerFactory<ProfileBloc>(
      () => ProfileBloc(
        ApplicationContainer.resolve<AuthRepository>(),
        ApplicationContainer.resolve<Logout>(),
      ),
    );

    // ── Chopper WineApiService ──
    ApplicationContainer.registerLazySingleton<WineApiService>(
      () => ApplicationContainer.resolve<ChopperClient>()
          .getService<WineApiService>(),
    );

    // ── Datasources ──
    // Vinhos reais do BFF (GET /v1/wines e /v1/wines/{id}).
    // O WineMockDatasource continua disponível para testes.
    ApplicationContainer.registerLazySingleton<WineDatasource>(
      () => WineRemoteDatasource(ApplicationContainer.resolve<WineApiService>()),
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
    ApplicationContainer.registerLazySingleton<GetWineHighlights>(
      () => GetWineHighlights(ApplicationContainer.resolve<WineRepository>()),
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

    // ── Home: Recomendações ──
    ApplicationContainer.registerLazySingleton<RecommendationRepository>(
      () => RecommendationRepositoryImpl(
        ApplicationContainer.resolve<RecommendationApiService>(),
      ),
    );
    ApplicationContainer.registerLazySingleton<GetRecommendations>(
      () => GetRecommendations(
        ApplicationContainer.resolve<RecommendationRepository>(),
      ),
    );
    ApplicationContainer.registerLazySingleton<GetFoodRecommendations>(
      () => GetFoodRecommendations(
        ApplicationContainer.resolve<RecommendationRepository>(),
      ),
    );
    ApplicationContainer.registerLazySingleton<GetWineMatch>(
      () => GetWineMatch(
        ApplicationContainer.resolve<RecommendationRepository>(),
      ),
    );
    ApplicationContainer.registerLazySingleton<SearchWines>(
      () => SearchWines(
        ApplicationContainer.resolve<RecommendationRepository>(),
      ),
    );

    // ── BLoCs ──
    ApplicationContainer.registerFactory<HomeBloc>(
      () => HomeBloc(
        ApplicationContainer.resolve<AuthRepository>(),
        ApplicationContainer.resolve<GetRecommendations>(),
        ApplicationContainer.resolve<Logout>(),
        ApplicationContainer.resolve<LoadFavoriteIds>(),
        ApplicationContainer.resolve<SetFavorite>(),
        ApplicationContainer.resolve<WatchFavoriteIds>(),
        ApplicationContainer.resolve<GetWineHighlights>(),
      ),
    );
    ApplicationContainer.registerFactory<SearchBloc>(
      () => SearchBloc(
        ApplicationContainer.resolve<SearchWines>(),
        ApplicationContainer.resolve<Logout>(),
        ApplicationContainer.resolve<SetFavorite>(),
        ApplicationContainer.resolve<WatchFavoriteIds>(),
      ),
    );
    ApplicationContainer.registerFactory<FoodWinesBloc>(
      () => FoodWinesBloc(
        ApplicationContainer.resolve<GetFoodRecommendations>(),
        ApplicationContainer.resolve<Logout>(),
        ApplicationContainer.resolve<SetFavorite>(),
        ApplicationContainer.resolve<WatchFavoriteIds>(),
      ),
    );
    ApplicationContainer.registerFactory<FavoritesListBloc>(
      () => FavoritesListBloc(
        ApplicationContainer.resolve<GetFavorites>(),
        ApplicationContainer.resolve<SetFavorite>(),
        ApplicationContainer.resolve<WatchFavoriteIds>(),
        ApplicationContainer.resolve<Logout>(),
      ),
    );
    ApplicationContainer.registerFactory<WineFavoriteBloc>(
      () => WineFavoriteBloc(
        ApplicationContainer.resolve<LoadFavoriteIds>(),
        ApplicationContainer.resolve<SetFavorite>(),
        ApplicationContainer.resolve<WatchFavoriteIds>(),
        ApplicationContainer.resolve<Logout>(),
      ),
    );
    ApplicationContainer.registerFactory<WineListBloc>(
      () => WineListBloc(ApplicationContainer.resolve<GetWines>()),
    );
    ApplicationContainer.registerFactory<WineDetailBloc>(
      () => WineDetailBloc(ApplicationContainer.resolve<GetWineById>()),
    );
    ApplicationContainer.registerFactory<WineMatchBloc>(
      () => WineMatchBloc(ApplicationContainer.resolve<GetWineMatch>()),
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

    // ── Cellar Feature ("Minha adega" = avaliações do usuário) ──
    ApplicationContainer.registerLazySingleton<CellarRepository>(
      () => CellarRepositoryImpl(
        ApplicationContainer.resolve<CellarApiService>(),
      ),
    );
    ApplicationContainer.registerLazySingleton<GetMyReviews>(
      () => GetMyReviews(ApplicationContainer.resolve<CellarRepository>()),
    );
    ApplicationContainer.registerFactory<CellarBloc>(
      () => CellarBloc(
        ApplicationContainer.resolve<GetMyReviews>(),
        ApplicationContainer.resolve<Logout>(),
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
