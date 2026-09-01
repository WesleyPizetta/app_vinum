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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userName = _getUserName();
    final greetingsText =
        getString(context, 'greetings_user').replaceAll('{name}', userName);

    return Text(
      greetingsText,
      style: theme.textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.onSurface,
      ),
    );
  }
}
