import 'package:flutter/material.dart';

import '../../../../core/navigation/application_route.dart';
import '../../../auth/domain/entity/user.dart';

class UserAvatarButton extends StatelessWidget {
  final User? user;

  const UserAvatarButton({super.key, this.user});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => Navigator.pushNamed(context, ApplicationRoute.me),
      icon: CircleAvatar(
        radius: 16,
        backgroundColor: user != null
            ? Theme.of(context).colorScheme.primaryContainer
            : Colors.grey.shade400,
        child: user != null
            ? Text(
                _getInitials(user!),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
              )
            : const Icon(Icons.person, size: 16, color: Colors.white),
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
}
