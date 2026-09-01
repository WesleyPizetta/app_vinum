import 'package:essentials/essentials.dart';
import 'package:flutter/material.dart';

import '../../../../core/navigation/application_route.dart';
import '../../../../core/widgets/app_version_badge.dart';
import '../../../auth/domain/entity/user.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          ApplicationContainer.resolve<ProfileBloc>()..add(ProfileStarted()),
      child: BlocListener<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state is ProfileLoggedOut) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              ApplicationRoute.login,
              (_) => false,
            );
          }
        },
        child: Scaffold(
          appBar: VinumAppBar(
            title: getString(context, 'profile'),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                tooltip: getString(context, 'settings'),
                onPressed: () =>
                    Navigator.pushNamed(context, ApplicationRoute.settings),
              ),
            ],
          ),
          body: BlocBuilder<ProfileBloc, ProfileState>(
            builder: (context, state) {
              return switch (state) {
                ProfileInitial() => const SizedBox.shrink(),
                ProfileLoaded(:final user) => _ProfileContent(user: user),
                ProfileLoggingOut() => const LoadingWidget(message: null),
                ProfileLoggedOut() => const SizedBox.shrink(),
                ProfileError(:final message) => VinumErrorWidget(
                    message: getString(context, message),
                    onRetry: () =>
                        context.read<ProfileBloc>().add(ProfileStarted()),
                  ),
              };
            },
          ),
        ),
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  final User user;

  const _ProfileContent({required this.user});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Dimens.spacing24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: Dimens.spacing32),
          Center(
            child: CircleAvatar(
              radius: 48,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              foregroundImage: _getAvatarImage(user),
              child: Text(
                _getInitials(user),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
              ),
            ),
          ),
          const SizedBox(height: Dimens.spacing24),
          if (user.name != null && user.name!.isNotEmpty)
            Text(
              user.name!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          const SizedBox(height: Dimens.spacing8),
          Text(
            user.email,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                ),
          ),
          const Spacer(),
          SecondaryButton(
            text: getString(context, 'settings'),
            onPressed: () =>
                Navigator.pushNamed(context, ApplicationRoute.settings),
          ),
          const SizedBox(height: Dimens.spacing12),
          OutlinedButton(
            onPressed: () =>
                context.read<ProfileBloc>().add(ProfileLogoutRequested()),
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
              side: BorderSide(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            child: Text(getString(context, 'end_session')),
          ),
          const SizedBox(height: Dimens.spacing16),
          const Center(child: AppVersionBadge()),
          const SizedBox(height: Dimens.spacing24),
        ],
      ),
    );
  }

  String _getInitials(User user) {
    if (user.name != null && user.name!.isNotEmpty) {
      final parts = user.name!.trim().split(' ');
      if (parts.length >= 2) {
        return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
      }
      return parts.first[0].toUpperCase();
    }
    return user.email[0].toUpperCase();
  }

  ImageProvider<Object>? _getAvatarImage(User user) {
    final avatarUrl = user.avatarUrl?.trim();
    if (avatarUrl == null || avatarUrl.isEmpty) {
      return null;
    }
    return NetworkImage(avatarUrl);
  }
}
