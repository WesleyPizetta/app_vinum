import 'package:essentials/essentials.dart';
import 'package:flutter/material.dart';

import '../../../../core/navigation/application_route.dart';
import '../../../auth/domain/entity/user.dart';
import '../../../cellar/presentation/page/cellar_page.dart';
import '../../../collections/presentation/page/collections_page.dart';
import '../../../explore/presentation/page/explore_page.dart';
import '../../../profile/presentation/widget/user_avatar_button.dart';
import '../../domain/entity/highlight_wine.dart';
import '../../domain/entity/recommended_wine.dart';
import '../bloc/home_bloc.dart';
import '../bloc/home_event.dart';
import '../bloc/home_state.dart';
import '../widget/highlight_wine_card.dart';
import '../widget/highlight_wines_horizontal_list.dart';
import '../widget/home_greetings_header.dart';
import '../widget/home_search_input.dart';
import '../widget/meal_category_horizontal_list.dart';
import '../widget/recommended_wines_section.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentTabIndex = 0;

  void _onTabSelected(int index) {
    if (_currentTabIndex != index) {
      setState(() {
        _currentTabIndex = index;
      });
    }
  }

  void _onScanPressed() {
    showVinumFeedbackModal(
      context,
      message: getString(context, 'scan_prompt'),
      icon: Icon(
        Icons.qr_code_scanner,
        size: Dimens.iconLarge,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final leftItems = [
      VinumNavItem(
        label: getString(context, 'nav_home'),
        icon: Icons.home_outlined,
        selectedIcon: Icons.home,
      ),
      VinumNavItem(
        label: getString(context, 'nav_explore'),
        icon: Icons.explore_outlined,
        selectedIcon: Icons.explore,
      ),
    ];

    final rightItems = [
      VinumNavItem(
        label: getString(context, 'nav_cellar'),
        icon: Icons.wine_bar_outlined,
        selectedIcon: Icons.wine_bar,
      ),
      VinumNavItem(
        label: getString(context, 'nav_collections'),
        icon: Icons.collections_bookmark_outlined,
        selectedIcon: Icons.collections_bookmark,
      ),
    ];

    final titles = [
      getString(context, 'home'),
      getString(context, 'nav_explore'),
      getString(context, 'nav_cellar'),
      getString(context, 'nav_collections'),
    ];

    final isHomeTab = _currentTabIndex == 0;

    return BlocProvider(
      create: (_) =>
          ApplicationContainer.resolve<HomeBloc>()..add(HomeStarted()),
      child: BlocListener<HomeBloc, HomeState>(
        listenWhen: (previous, current) =>
            current is HomeSessionExpired ||
            (current is HomeLoaded && current.favoriteErrorMessage != null),
        listener: (context, state) {
          if (state is HomeLoaded) {
            // Falha ao favoritar (o ícone já voltou ao estado anterior).
            final error = state.favoriteErrorMessage;
            if (error != null) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(content: Text(getString(context, error))),
                );
            }
            return;
          }
          if (state is HomeSessionExpired) {
            // Mesmo fluxo do onboarding: logout já feito pelo bloc.
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(getString(context, state.message))),
            );
            Navigator.pushNamedAndRemoveUntil(
              context,
              ApplicationRoute.login,
              (_) => false,
            );
          }
        },
        child: Scaffold(
          appBar: VinumAppBar(
            titleWidget: isHomeTab
                ? Text(
                    'Vinum',
                    style: TextStyle(
                      fontFamily: 'Amarante',
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  )
                : Text(titles[_currentTabIndex]),
            centerTitle: !isHomeTab,
            backgroundColor:
                isHomeTab ? Theme.of(context).scaffoldBackgroundColor : null,
            foregroundColor:
                isHomeTab ? Theme.of(context).colorScheme.primary : null,
            showBackButton: false,
            actions: [
              BlocBuilder<HomeBloc, HomeState>(
                builder: (context, state) {
                  final user = state is HomeLoaded ? state.currentUser : null;
                  return UserAvatarButton(
                    user: user,
                    // Refazer o quiz ou trocar o apelido pelo perfil:
                    // recarrega a home (e a saudação).
                    onProfileUpdated: () => context
                        .read<HomeBloc>()
                        .add(HomeStarted(refreshUser: true)),
                  );
                },
              ),
              VinumNotificationButton(
                unreadCount: 3,
                color: isHomeTab
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onPrimary,
                badgeColor: isHomeTab
                    ? Theme.of(context).colorScheme.secondary
                    : Theme.of(context).colorScheme.secondary,
                onPressed: () {
                  showVinumFeedbackModal(
                    context,
                    message: 'Central de Notificações (em breve)',
                    icon: Icon(
                      Icons.notifications_active_outlined,
                      size: Dimens.iconLarge,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  );
                },
              ),
            ],
          ),
          body: IndexedStack(
            index: _currentTabIndex,
            children: const [
              _HomeTabContent(),
              ExplorePage(),
              CellarPage(),
              CollectionsPage(),
            ],
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
          floatingActionButton: FloatingActionButton(
            tooltip: getString(context, 'nav_scan'),
            elevation: Dimens.elevationMedium,
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            onPressed: _onScanPressed,
            child: const Icon(Icons.qr_code_scanner, size: Dimens.iconMedium),
          ),
          bottomNavigationBar: VinumBottomNavigationBar(
            currentIndex: _currentTabIndex,
            onTap: _onTabSelected,
            leftItems: leftItems,
            rightItems: rightItems,
          ),
        ),
      ),
    );
  }
}

// ── 1. Conteúdo da Aba Início (Home) ──────────────────────────────────────────

class _HomeTabContent extends StatelessWidget {
  const _HomeTabContent();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        return switch (state) {
          HomeInitial() => const SizedBox.shrink(),
          HomeLoading() ||
          HomeSessionExpired() =>
            const LoadingWidget(message: null),
          HomeLoaded(
            :final welcomeMessage,
            :final currentUser,
            :final recommendations,
            :final recommendationsStatus,
            :final recommendationsErrorMessage,
            :final highlights,
            :final highlightsStatus,
          ) =>
            _HomeLoadedView(
              welcomeMessage: welcomeMessage,
              currentUser: currentUser,
              recommendations: recommendations,
              recommendationsStatus: recommendationsStatus,
              recommendationsErrorMessage: recommendationsErrorMessage,
              highlights: highlights,
              highlightsStatus: highlightsStatus,
            ),
          HomeError(:final message) => VinumErrorWidget(
              message: message,
              onRetry: () => context.read<HomeBloc>().add(HomeStarted()),
            ),
        };
      },
    );
  }
}

class _HomeLoadedView extends StatelessWidget {
  final String welcomeMessage;
  final User? currentUser;
  final List<RecommendedWine> recommendations;
  final RecommendationsStatus recommendationsStatus;
  final String? recommendationsErrorMessage;
  final List<HighlightWine> highlights;
  final HighlightsStatus highlightsStatus;

  const _HomeLoadedView({
    required this.welcomeMessage,
    this.currentUser,
    this.recommendations = const [],
    this.recommendationsStatus = RecommendationsStatus.loaded,
    this.recommendationsErrorMessage,
    this.highlights = const [],
    this.highlightsStatus = HighlightsStatus.loaded,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Falha ou lista vazia: a seção inteira (título + lista) some.
    final showHighlights = highlightsStatus == HighlightsStatus.loading ||
        (highlightsStatus == HighlightsStatus.loaded && highlights.isNotEmpty);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: Dimens.spacing24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Greetings
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Dimens.spacing24),
            child: HomeGreetingsHeader(currentUser: currentUser),
          ),
          const SizedBox(height: Dimens.spacing16),

          // Campo de busca (Input)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: Dimens.spacing24),
            child: HomeSearchInput(),
          ),

          const SizedBox(height: Dimens.spacing24),

          // Seção "O que temos para hoje?" + Scroll Horizontal de Refeições/Harmonização
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Dimens.spacing24),
            child: Text(
              getString(context, 'home_pairing_section_title'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(height: Dimens.spacing12),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: Dimens.spacing24),
            child: MealCategoryHorizontalList(),
          ),

          const SizedBox(height: Dimens.spacing24),

          // Seção "Sugestões para você" + Scroll Horizontal de Recomendações
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Dimens.spacing24),
            child: Text(
              getString(context, 'home_recommendations_section_title'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(height: Dimens.spacing12),

          RecommendedWinesSection(
            status: recommendationsStatus,
            recommendations: recommendations,
            errorMessage: recommendationsErrorMessage,
          ),

          // Seção "Destaques da Semana" + Scroll Horizontal de Destaques
          if (showHighlights) ...[
            const SizedBox(height: Dimens.spacing24),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: Dimens.spacing24),
              child: Text(
                getString(context, 'home_highlights_section_title'),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: Dimens.spacing12),
            if (highlightsStatus == HighlightsStatus.loading)
              const SizedBox(
                height: HighlightWineCard.height,
                child: LoadingWidget(),
              )
            else
              Padding(
                padding: const EdgeInsets.only(left: Dimens.spacing24),
                child: HighlightWinesHorizontalList(
                  highlights: highlights,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

