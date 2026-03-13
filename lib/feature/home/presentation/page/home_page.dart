import 'package:essentials/essentials.dart';
import 'package:flutter/material.dart';

import '../../../../core/navigation/application_route.dart';
import '../bloc/home_bloc.dart';
import '../bloc/home_event.dart';
import '../bloc/home_state.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          ApplicationContainer.resolve<HomeBloc>()..add(HomeStarted()),
      child: Scaffold(
        appBar: VinumAppBar(
          title: getString(context, 'home'),
          showBackButton: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () =>
                  Navigator.pushNamed(context, ApplicationRoute.settings),
            ),
          ],
        ),
        body: BlocBuilder<HomeBloc, HomeState>(
          builder: (context, state) {
            return switch (state) {
              HomeInitial() => const SizedBox.shrink(),
              HomeLoading() =>
                const LoadingWidget(message: null),
              HomeLoaded(:final welcomeMessage) => _HomeContent(
                  welcomeMessage: welcomeMessage,
                ),
              HomeError(:final message) => VinumErrorWidget(
                  message: message,
                  onRetry: () =>
                      context.read<HomeBloc>().add(HomeStarted()),
                ),
            };
          },
        ),
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  final String welcomeMessage;

  const _HomeContent({required this.welcomeMessage});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Dimens.spacing24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: Dimens.spacing48),
          Icon(
            Icons.wine_bar,
            size: 80,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: Dimens.spacing24),
          Text(
            getString(context, 'welcome'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: Dimens.spacing8),
          Text(
            getString(context, 'welcome_subtitle'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                ),
          ),
          const SizedBox(height: Dimens.spacing48),
          PrimaryButton(
            text: getString(context, 'settings'),
            onPressed: () =>
                Navigator.pushNamed(context, ApplicationRoute.settings),
          ),
        ],
      ),
    );
  }
}
