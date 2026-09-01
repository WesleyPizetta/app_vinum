import 'package:essentials/essentials.dart';
import 'package:flutter/material.dart';

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
import '../widget/highlight_wines_horizontal_list.dart';
import '../widget/home_greetings_header.dart';
import '../widget/home_search_input.dart';
import '../widget/meal_category_horizontal_list.dart';
import '../widget/recommended_wines_horizontal_list.dart';

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
      child: PopScope(
        canPop: _currentTabIndex == 0,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          if (_currentTabIndex != 0) {
            setState(() {
              _currentTabIndex = 0;
            });
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
                  return UserAvatarButton(user: user);
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
            onScanTap: _onScanPressed,
            leftItems: leftItems,
            rightItems: rightItems,
            scanLabel: getString(context, 'nav_scan'),
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
          HomeLoading() => const LoadingWidget(message: null),
          HomeLoaded(
            :final welcomeMessage,
            :final currentUser,
            :final recommendations,
            :final highlights,
          ) =>
            _HomeLoadedView(
              welcomeMessage: welcomeMessage,
              currentUser: currentUser,
              recommendations: recommendations,
              highlights: highlights,
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
  final List<HighlightWine> highlights;

  const _HomeLoadedView({
    required this.welcomeMessage,
    this.currentUser,
    this.recommendations = const [],
    this.highlights = const [],
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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

          Padding(
            padding: const EdgeInsets.only(left: Dimens.spacing24),
            child: RecommendedWinesHorizontalList(
              recommendations: recommendations,
            ),
          ),

          const SizedBox(height: Dimens.spacing24),

          // Seção "Destaques da Semana" + Scroll Horizontal de Destaques
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Dimens.spacing24),
            child: Text(
              getString(context, 'home_highlights_section_title'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(height: Dimens.spacing12),

          Padding(
            padding: const EdgeInsets.only(left: Dimens.spacing24),
            child: HighlightWinesHorizontalList(
              highlights: highlights,
            ),
          ),
        ],
      ),
    );
  }
}


