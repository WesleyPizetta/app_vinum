import 'package:essentials/essentials.dart';
import 'package:flutter/material.dart';

import '../../../../core/navigation/application_route.dart';
import '../bloc/wine_favorite_bloc.dart';

/// Botão de favorito de um vinho (ex.: actions do `SliverAppBar` do
/// detalhe). Cria o próprio [WineFavoriteBloc], sincronizado com o cache de
/// favoritos; falha mostra SnackBar e 401 volta ao login.
class FavoriteIconButton extends StatelessWidget {
  final String wineId;

  /// Cor do ícone; `null` herda do `IconTheme` (ex.: da AppBar).
  final Color? color;

  const FavoriteIconButton({super.key, required this.wineId, this.color});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<WineFavoriteBloc>(
      create: (_) => ApplicationContainer.resolve<WineFavoriteBloc>()
        ..add(WineFavoriteStarted(wineId)),
      child: BlocConsumer<WineFavoriteBloc, WineFavoriteState>(
        listenWhen: (previous, current) =>
            current.errorMessage != null ||
            (current.sessionExpired && !previous.sessionExpired),
        listener: (context, state) {
          if (state.sessionExpired) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(getString(context, 'session_expired'))),
            );
            Navigator.pushNamedAndRemoveUntil(
              context,
              ApplicationRoute.login,
              (_) => false,
            );
            return;
          }
          final error = state.errorMessage;
          if (error != null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(content: Text(getString(context, error))),
              );
          }
        },
        builder: (context, state) {
          final isFavorite = state.isFavorite ?? false;
          return IconButton(
            tooltip: getString(
              context,
              isFavorite ? 'favorite_remove' : 'favorite_add',
            ),
            color: color,
            onPressed: state.isFavorite == null || state.sessionExpired
                ? null
                : () =>
                    context.read<WineFavoriteBloc>().add(WineFavoriteToggled()),
            icon: Icon(isFavorite ? Icons.bookmark : Icons.bookmark_outline),
          );
        },
      ),
    );
  }
}
