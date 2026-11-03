import 'package:flutter/material.dart';

import '../../../../core/navigation/application_route.dart';
import '../../../auth/domain/entity/user.dart';

class UserAvatarButton extends StatelessWidget {
  final User? user;

  /// Chamado quando o perfil é fechado após uma alteração que afeta as
  /// recomendações ou a saudação (ex.: quiz de paladar refeito ou apelido
  /// alterado) — a tela de perfil faz `Navigator.pop(context, true)` nesses
  /// casos.
  final VoidCallback? onProfileUpdated;

  const UserAvatarButton({super.key, this.user, this.onProfileUpdated});

  Future<void> _openProfile(BuildContext context) async {
    final updated = await Navigator.pushNamed<Object?>(
      context,
      ApplicationRoute.me,
    );
    if (updated == true) onProfileUpdated?.call();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => _openProfile(context),
      icon: CircleAvatar(
        radius: 16,
        backgroundColor: user != null
            ? Theme.of(context).colorScheme.primaryContainer
            : Colors.grey.shade400,
        foregroundImage: user != null ? _getAvatarImage(user!) : null,
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

  ImageProvider<Object>? _getAvatarImage(User user) {
    final avatarUrl = user.avatarUrl?.trim();
    if (avatarUrl == null || avatarUrl.isEmpty) {
      return null;
    }
    return NetworkImage(avatarUrl);
  }
}
