import 'package:essentials/essentials.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Exibe a versão do app e o ambiente atual.
/// Visível apenas em modo debug (kDebugMode).
class AppVersionBadge extends StatefulWidget {
  const AppVersionBadge({super.key});

  @override
  State<AppVersionBadge> createState() => _AppVersionBadgeState();
}

class _AppVersionBadgeState extends State<AppVersionBadge> {
  String _label = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final info = await PackageInfo.fromPlatform();
    final env = ApplicationContainer.resolve<Environment>();
    setState(() {
      _label = 'v${info.version}+${info.buildNumber} · ${env.name}';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode || _label.isEmpty) return const SizedBox.shrink();

    final parts = _label.split(' · ');
    final version = parts.isNotEmpty ? parts[0] : _label;
    final env = parts.length > 1 ? parts[1] : '';

    final envStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w700,
        );

    final versionStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.secondary,
          fontWeight: FontWeight.w600,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (env.isNotEmpty) Text(env, style: envStyle),
        Text(version, style: versionStyle),
      ],
    );
  }
}
