import '../../../auth/domain/entity/user.dart';
import '../../domain/entity/highlight_wine.dart';
import '../../domain/entity/recommended_wine.dart';

sealed class HomeState {}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

/// Estado da seção "Sugestões para você", independente do resto da home.
enum RecommendationsStatus {
  loading,
  loaded,
  empty,
  error,

  /// 409 `ONBOARDING_REQUIRED`: a seção mostra CTA para fazer o quiz.
  onboardingRequired,
}

/// Estado da seção "Destaques da Semana". Falhas não aparecem para o
/// usuário: a seção simplesmente some ([unavailable]).
enum HighlightsStatus {
  loading,
  loaded,

  /// Falha ao carregar ou nenhum destaque: a seção fica oculta.
  unavailable,
}

class HomeLoaded extends HomeState {
  final String welcomeMessage;
  final User? currentUser;
  final List<RecommendedWine> recommendations;
  final RecommendationsStatus recommendationsStatus;

  /// Chave i18n do erro da seção (quando [recommendationsStatus] é `error`).
  final String? recommendationsErrorMessage;
  final List<HighlightWine> highlights;
  final HighlightsStatus highlightsStatus;

  /// Chave i18n de falha ao favoritar (SnackBar). Transitório: não é copiado
  /// por [copyWith], então cada falha gera um único aviso.
  final String? favoriteErrorMessage;

  HomeLoaded({
    required this.welcomeMessage,
    this.currentUser,
    this.recommendations = const [],
    this.recommendationsStatus = RecommendationsStatus.loaded,
    this.recommendationsErrorMessage,
    this.highlights = const [],
    this.highlightsStatus = HighlightsStatus.loaded,
    this.favoriteErrorMessage,
  });

  HomeLoaded copyWith({
    List<RecommendedWine>? recommendations,
    RecommendationsStatus? recommendationsStatus,
    String? recommendationsErrorMessage,
    bool clearRecommendationsError = false,
    List<HighlightWine>? highlights,
    HighlightsStatus? highlightsStatus,
    String? favoriteErrorMessage,
  }) {
    return HomeLoaded(
      welcomeMessage: welcomeMessage,
      currentUser: currentUser,
      recommendations: recommendations ?? this.recommendations,
      recommendationsStatus:
          recommendationsStatus ?? this.recommendationsStatus,
      recommendationsErrorMessage: clearRecommendationsError
          ? null
          : (recommendationsErrorMessage ?? this.recommendationsErrorMessage),
      highlights: highlights ?? this.highlights,
      highlightsStatus: highlightsStatus ?? this.highlightsStatus,
      favoriteErrorMessage: favoriteErrorMessage,
    );
  }
}

class HomeError extends HomeState {
  final String message;
  HomeError({required this.message});
}

/// Sessão expirada (401) ao carregar a home: logout já executado, a página
/// deve voltar ao login (mesmo fluxo do onboarding).
class HomeSessionExpired extends HomeState {
  /// Chave i18n.
  final String message;
  HomeSessionExpired({required this.message});
}
