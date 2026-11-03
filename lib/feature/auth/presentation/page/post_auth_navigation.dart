import 'package:flutter/material.dart';

import '../../../../core/navigation/application_route.dart';
import '../../../profile/presentation/page/nickname_args.dart';
import '../../domain/entity/post_auth_destination.dart';
import '../../domain/entity/user.dart';

/// Substitui a pilha pela próxima tela do fluxo de entrada de [user]:
/// apelido (primeiro acesso, sem @handle) → quiz de onboarding → home.
void navigateAfterAuth(BuildContext context, User user) {
  switch (PostAuthDestination.forUser(user)) {
    case PostAuthDestination.nickname:
      Navigator.pushNamedAndRemoveUntil(
        context,
        ApplicationRoute.nickname,
        (_) => false,
        arguments: const NicknameArgs(),
      );
    case PostAuthDestination.onboarding:
      Navigator.pushNamedAndRemoveUntil(
        context,
        ApplicationRoute.onboarding,
        (_) => false,
      );
    case PostAuthDestination.home:
      Navigator.pushNamedAndRemoveUntil(
        context,
        ApplicationRoute.home,
        (_) => false,
      );
  }
}
