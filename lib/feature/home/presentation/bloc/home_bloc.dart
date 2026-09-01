import 'package:essentials/essentials.dart';
import 'package:flutter/material.dart';

import '../../../auth/domain/repository/auth_repository.dart';
import '../../domain/entity/highlight_wine.dart';
import '../../domain/entity/recommended_wine.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final AuthRepository _authRepository;

  HomeBloc(this._authRepository) : super(HomeInitial()) {
    on<HomeStarted>(_onStarted);
    on<HomeRecommendationFavoriteToggled>(_onFavoriteToggled);
    on<HomeHighlightFavoriteToggled>(_onHighlightFavoriteToggled);
  }

  static const List<RecommendedWine> _mockRecommendations = [
    RecommendedWine(
      id: 'rec_1',
      name: 'Almaviva 2019',
      rating: 4.8,
      price: 650.0,
      affinityPercentage: 95,
      isFavorite: true,
    ),
    RecommendedWine(
      id: 'rec_2',
      name: 'Catena Zapata',
      rating: 4.6,
      price: 180.0,
      affinityPercentage: 91,
      isFavorite: true,
    ),
    RecommendedWine(
      id: 'rec_3',
      name: 'Mendel Unus',
      rating: 4.7,
      price: 290.0,
      affinityPercentage: 89,
      isFavorite: true,
    ),
    RecommendedWine(
      id: 'rec_4',
      name: 'Montes Alpha M',
      rating: 4.8,
      price: 520.0,
      affinityPercentage: 86,
      isFavorite: false,
    ),
    RecommendedWine(
      id: 'rec_5',
      name: 'Pera Manca',
      rating: 4.9,
      price: 980.0,
      affinityPercentage: 84,
      isFavorite: false,
    ),
  ];

  static const List<HighlightWine> _mockHighlights = [
    HighlightWine(
      id: 'hl_1',
      name: 'Norton Reserva Malbec',
      rating: 4.3,
      viewsCountLabel: '12.5k',
      isFavorite: true,
      bannerColor: Color(0xFF6B1F32), // Tom bordô/vinho tinto escuro
    ),
    HighlightWine(
      id: 'hl_2',
      name: 'Zuccardi Serie A',
      rating: 4.4,
      viewsCountLabel: '9k',
      isFavorite: true,
      bannerColor: Color(0xFFCFA035), // Tom amarelo/ouro queimado
    ),
    HighlightWine(
      id: 'hl_3',
      name: 'Tinto Encorpado',
      rating: 4.5,
      viewsCountLabel: '14k',
      isFavorite: false,
      bannerColor: Color(0xFF4A121A), // Tom rubi escuro
    ),
    HighlightWine(
      id: 'hl_4',
      name: 'Catena Malbec',
      rating: 4.7,
      viewsCountLabel: '18k',
      isFavorite: true,
      bannerColor: Color(0xFF2C5570), // Tom azul escuro elegante
    ),
    HighlightWine(
      id: 'hl_5',
      name: 'Salentein Reserve',
      rating: 4.6,
      viewsCountLabel: '11k',
      isFavorite: false,
      bannerColor: Color(0xFF38633F), // Tom verde oliva profundo
    ),
  ];

  Future<void> _onStarted(HomeStarted event, Emitter<HomeState> emit) async {
    emit(HomeLoading());
    await Future.delayed(const Duration(milliseconds: 500));
    emit(HomeLoaded(
      welcomeMessage: 'Vinum',
      currentUser: _authRepository.getCurrentUser(),
      recommendations: _mockRecommendations,
      highlights: _mockHighlights,
    ));
  }

  void _onFavoriteToggled(
    HomeRecommendationFavoriteToggled event,
    Emitter<HomeState> emit,
  ) {
    if (state is HomeLoaded) {
      final current = state as HomeLoaded;
      final updatedList = current.recommendations.map((wine) {
        if (wine.id == event.wineId) {
          return wine.copyWith(isFavorite: !wine.isFavorite);
        }
        return wine;
      }).toList();

      emit(HomeLoaded(
        welcomeMessage: current.welcomeMessage,
        currentUser: current.currentUser,
        recommendations: updatedList,
        highlights: current.highlights,
      ));
    }
  }

  void _onHighlightFavoriteToggled(
    HomeHighlightFavoriteToggled event,
    Emitter<HomeState> emit,
  ) {
    if (state is HomeLoaded) {
      final current = state as HomeLoaded;
      final updatedList = current.highlights.map((wine) {
        if (wine.id == event.wineId) {
          return wine.copyWith(isFavorite: !wine.isFavorite);
        }
        return wine;
      }).toList();

      emit(HomeLoaded(
        welcomeMessage: current.welcomeMessage,
        currentUser: current.currentUser,
        recommendations: current.recommendations,
        highlights: updatedList,
      ));
    }
  }
}
