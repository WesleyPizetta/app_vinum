import 'package:essentials/essentials.dart';
import 'package:flutter/material.dart';

import '../../../auth/domain/entity/user.dart';

class HomeGreetingsHeader extends StatelessWidget {
  final User? currentUser;

  const HomeGreetingsHeader({super.key, this.currentUser});

  String _getUserName() {
    final name = currentUser?.name?.trim();
    if (name != null && name.isNotEmpty) {
      return name.split(' ').first;
    }
    return 'Sommelier';
  }

  /// Saudação pelo apelido ("Olá, wes_pizetta!") quando existir; senão,
  /// pelo primeiro nome.
  String _greetingsText(BuildContext context) {
    final nickname = currentUser?.nickname?.trim();
    if (nickname != null && nickname.isNotEmpty) {
      return getString(context, 'greetings_user_nickname')
          .replaceAll('{nickname}', nickname);
    }
    return getString(context, 'greetings_user')
        .replaceAll('{name}', _getUserName());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final greetingsText = _greetingsText(context);

    return Text(
      greetingsText,
      style: theme.textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.onSurface,
      ),
    );
  }
}
