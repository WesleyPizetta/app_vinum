import 'package:essentials/essentials.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/nickname_rules.dart';
import '../bloc/nickname_field_cubit.dart';
import '../bloc/nickname_field_state.dart';
import 'nickname_input_formatter.dart';
import 'nickname_messages.dart';

/// Campo "Como você quer ser chamado?" (@handle).
///
/// Requer um [NicknameFieldCubit] acima na árvore. Filtra o que é digitado
/// (minúsculas, sem espaços/acentos/símbolos), mostra a validação local na
/// hora e o resultado da verificação de disponibilidade no servidor
/// (verificando / disponível / motivo da recusa).
///
/// Mudanças feitas por código no [controller] não passam por [onChanged]:
/// chame `NicknameFieldCubit.changed`/`start` nesses casos.
class NicknameField extends StatelessWidget {
  static const Key fieldKey = Key('nickname_field');

  final TextEditingController controller;

  /// Chamado quando o **usuário** altera o texto (depois do cubit).
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;
  final bool enabled;
  final TextInputAction textInputAction;

  const NicknameField({
    super.key,
    required this.controller,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.enabled = true,
    this.textInputAction = TextInputAction.next,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NicknameFieldCubit, NicknameFieldState>(
      builder: (context, state) {
        String? helperText;
        String? errorText;
        TextStyle? helperStyle;
        switch (state.status) {
          case NicknameFieldStatus.empty:
            helperText = getString(context, 'nickname_helper');
          case NicknameFieldStatus.checking:
            helperText = getString(context, 'nickname_checking');
          case NicknameFieldStatus.available:
            helperText = getString(context, 'nickname_available')
                .replaceAll('{nickname}', state.nickname);
            helperStyle = TextStyle(color: _availableColor(context));
          case NicknameFieldStatus.invalid:
          case NicknameFieldStatus.unavailable:
          case NicknameFieldStatus.error:
            errorText = getString(context, nicknameMessageKey(state.errorCode));
        }

        return TextField(
          key: fieldKey,
          controller: controller,
          focusNode: focusNode,
          enabled: enabled,
          autocorrect: false,
          enableSuggestions: false,
          textCapitalization: TextCapitalization.none,
          keyboardType: TextInputType.text,
          textInputAction: textInputAction,
          inputFormatters: [
            const NicknameInputFormatter(),
            LengthLimitingTextInputFormatter(NicknameRules.maxLength),
          ],
          onChanged: (value) {
            context.read<NicknameFieldCubit>().changed(value);
            onChanged?.call(value);
          },
          onSubmitted: onSubmitted,
          decoration: InputDecoration(
            labelText: getString(context, 'nickname_label'),
            hintText: getString(context, 'nickname_hint'),
            prefixIcon: const Icon(Icons.alternate_email),
            suffixIcon: state.status == NicknameFieldStatus.empty
                ? null
                : _NicknameStatusIcon(state: state),
            helperText: helperText,
            helperStyle: helperStyle,
            helperMaxLines: 3,
            errorText: errorText,
            errorMaxLines: 3,
          ),
        );
      },
    );
  }

  static Color _availableColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? Colors.green.shade300
          : Colors.green.shade700;
}

class _NicknameStatusIcon extends StatelessWidget {
  final NicknameFieldState state;

  const _NicknameStatusIcon({required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    switch (state.status) {
      case NicknameFieldStatus.empty:
        return const SizedBox.shrink();
      case NicknameFieldStatus.checking:
        return const Padding(
          padding: EdgeInsets.all(Dimens.spacing12),
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      case NicknameFieldStatus.available:
        return Icon(
          Icons.check_circle,
          color: NicknameField._availableColor(context),
        );
      case NicknameFieldStatus.invalid:
      case NicknameFieldStatus.unavailable:
        return Icon(Icons.cancel, color: theme.colorScheme.error);
      case NicknameFieldStatus.error:
        return Icon(Icons.error_outline, color: theme.colorScheme.error);
    }
  }
}
