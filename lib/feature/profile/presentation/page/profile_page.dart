import 'package:essentials/essentials.dart';
import 'package:flutter/material.dart';

import '../../../../core/navigation/application_route.dart';
import '../../../../core/widgets/app_version_badge.dart';
import '../../../auth/domain/entity/user.dart';
import '../../../auth/presentation/page/onboarding_args.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';
import 'nickname_args.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  /// Apelido alterado nesta visita: ao sair, o perfil devolve `true` para
  /// quem o abriu (ex.: home, via `UserAvatarButton.onProfileUpdated`)
  /// recarregar a saudação.
  bool _profileUpdated = false;

  void _onNicknameChanged() {
    if (!mounted) return;
    setState(() => _profileUpdated = true);
  }

  /// Voltar (seta da app bar ou botão do sistema).
  void _close() {
    Navigator.of(context).pop(_profileUpdated ? true : null);
  }

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
        child: PopScope(
          // Depois de alterar o apelido, o voltar do sistema também devolve
          // `true` (ver [_close]).
          canPop: !_profileUpdated,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            _close();
          },
          child: Scaffold(
            appBar: VinumAppBar(
              title: getString(context, 'profile'),
              onBackPressed: _close,
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
                  ProfileLoaded(:final user) => _ProfileContent(
                      user: user,
                      onNicknameChanged: _onNicknameChanged,
                    ),
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
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  final User user;

  /// Chamado após salvar um novo apelido (a home precisa recarregar a
  /// saudação quando o perfil for fechado).
  final VoidCallback onNicknameChanged;

  const _ProfileContent({required this.user, required this.onNicknameChanged});

  @override
  Widget build(BuildContext context) {
    // Rolável: em telas pequenas o conteúdo não estoura a altura.
    return SingleChildScrollView(
      child: Padding(
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
          if (user.hasNickname) ...[
            const SizedBox(height: Dimens.spacing4),
            Text(
              '@${user.nickname!.trim()}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
          Center(
            child: TextButton.icon(
              onPressed: () => _changeNickname(context),
              icon: const Icon(Icons.edit_outlined, size: Dimens.iconSmall),
              label: Text(getString(context, 'profile_change_nickname')),
            ),
          ),
          Text(
            user.email,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                ),
          ),
          const SizedBox(height: Dimens.spacing32),
          SecondaryButton(
            text: getString(context, 'profile_retake_quiz'),
            onPressed: () => _retakeQuiz(context),
          ),
          const SizedBox(height: Dimens.spacing12),
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
    ),
    );
  }

  /// Abre o quiz em modo "refazer". Se o perfil de gosto foi atualizado,
  /// volta para quem abriu o perfil (ex.: home) com `true`, para que as
  /// recomendações sejam recarregadas.
  Future<void> _retakeQuiz(BuildContext context) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final successMessage = getString(context, 'profile_retake_quiz_success');

    final updated = await navigator.pushNamed<Object?>(
      ApplicationRoute.onboarding,
      arguments: const OnboardingArgs(retake: true),
    );
    if (updated != true) return;

    messenger.showSnackBar(SnackBar(content: Text(successMessage)));
    if (navigator.canPop()) navigator.pop(true);
  }

  /// Abre a tela de apelido em modo edição. Ao salvar, ela volta com o novo
  /// apelido (já gravado no usuário em cache) e o perfil é recarregado; ao
  /// fechar o perfil, quem o abriu (ex.: home) recarrega a saudação.
  Future<void> _changeNickname(BuildContext context) async {
    final bloc = context.read<ProfileBloc>();
    final messenger = ScaffoldMessenger.of(context);
    final savedMessage = getString(context, 'nickname_saved');

    final result = await Navigator.of(context).pushNamed<Object?>(
      ApplicationRoute.nickname,
      arguments: const NicknameArgs(editMode: true),
    );
    if (result is! String || bloc.isClosed) return;

    bloc.add(ProfileStarted());
    onNicknameChanged();
    messenger.showSnackBar(SnackBar(content: Text(savedMessage)));
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
