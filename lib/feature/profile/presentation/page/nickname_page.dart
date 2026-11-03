import 'package:essentials/essentials.dart';
import 'package:flutter/material.dart';

import '../../../../core/navigation/application_route.dart';
import '../../../auth/presentation/page/post_auth_navigation.dart';
import '../../domain/entity/nickname_failure_code.dart';
import '../../domain/nickname_rules.dart';
import '../bloc/nickname_field_cubit.dart';
import '../bloc/nickname_field_state.dart';
import '../bloc/nickname_page_cubit.dart';
import '../bloc/nickname_page_state.dart';
import '../widget/nickname_field.dart';
import '../widget/nickname_messages.dart';
import 'nickname_args.dart';

/// "Como você quer ser chamado?" — escolha/edição do apelido público.
///
/// `arguments`: [NicknameArgs]. Sem argumentos = primeiro acesso (não pode
/// voltar; oferece sair da conta; ao salvar segue para o quiz ou a home).
class NicknamePage extends StatelessWidget {
  const NicknamePage({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final editMode = args is NicknameArgs && args.editMode;

    return MultiBlocProvider(
      providers: [
        BlocProvider<NicknamePageCubit>(
          create: (_) => ApplicationContainer.resolve<NicknamePageCubit>(),
        ),
        BlocProvider<NicknameFieldCubit>(
          create: (_) => ApplicationContainer.resolve<NicknameFieldCubit>(),
        ),
      ],
      child: _NicknameView(editMode: editMode),
    );
  }
}

class _NicknameView extends StatefulWidget {
  final bool editMode;

  const _NicknameView({required this.editMode});

  @override
  State<_NicknameView> createState() => _NicknameViewState();
}

class _NicknameViewState extends State<_NicknameView> {
  final _controller = TextEditingController();
  String? _ownNickname;

  @override
  void initState() {
    super.initState();
    final user = context.read<NicknamePageCubit>().currentUser;
    _ownNickname = user != null && user.hasNickname
        ? NicknameRules.normalize(user.nickname!)
        : null;
    final initial = _ownNickname ??
        NicknameRules.suggestFromName(
          (user?.name?.trim().isNotEmpty ?? false) ? user!.name : user?.email,
        );
    _controller.text = initial;
    context
        .read<NicknameFieldCubit>()
        .start(initial: initial, ownNickname: _ownNickname);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final fieldCubit = context.read<NicknameFieldCubit>();
    final fieldState = fieldCubit.state;
    if (!fieldState.isAvailable) {
      fieldCubit.submitAttempted();
      return;
    }
    // Edição sem mudança: nada a salvar.
    if (widget.editMode && fieldState.nickname == _ownNickname) {
      Navigator.of(context).pop();
      return;
    }
    FocusScope.of(context).unfocus();
    context.read<NicknamePageCubit>().save(fieldState.nickname);
  }

  void _onPageState(BuildContext context, NicknamePageState state) {
    switch (state) {
      case NicknamePageIdle(:final failureCode, :final nickname):
        if (failureCode == null) return;
        if (NicknameFailureCode.isRuleViolation(failureCode) &&
            nickname != null) {
          // Ex.: alguém pegou o apelido entre a verificação e o envio.
          context
              .read<NicknameFieldCubit>()
              .rejectedByServer(nickname, failureCode);
        } else {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(
              content: Text(
                getString(context, nicknameMessageKey(failureCode)),
              ),
            ));
        }
      case NicknamePageSaved(:final nickname, :final user):
        if (widget.editMode) {
          Navigator.of(context).pop(nickname);
        } else if (user != null) {
          // Fluxo normal: quiz de onboarding (se pendente) ou home.
          navigateAfterAuth(context, user.copyWith(nickname: nickname));
        } else {
          Navigator.pushNamedAndRemoveUntil(
            context,
            ApplicationRoute.login,
            (_) => false,
          );
        }
      case NicknamePageLoggedOut(:final message):
        if (message != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(getString(context, message))),
          );
        }
        Navigator.pushNamedAndRemoveUntil(
          context,
          ApplicationRoute.login,
          (_) => false,
        );
      case NicknamePageSaving():
      case NicknamePageLoggingOut():
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final editMode = widget.editMode;

    return BlocListener<NicknamePageCubit, NicknamePageState>(
      listener: _onPageState,
      child: PopScope(
        // Primeiro acesso: o apelido é obrigatório (só dá para sair da conta).
        canPop: editMode,
        child: Scaffold(
          appBar: VinumAppBar(
            title: getString(context, 'nickname_page_title'),
            showBackButton: editMode,
            actions: editMode
                ? null
                : [
                    BlocBuilder<NicknamePageCubit, NicknamePageState>(
                      builder: (context, state) => TextButton(
                        onPressed: state is NicknamePageSaving ||
                                state is NicknamePageLoggingOut
                            ? null
                            : () => context.read<NicknamePageCubit>().logout(),
                        child: Text(getString(context, 'nickname_page_logout')),
                      ),
                    ),
                  ],
          ),
          body: SafeArea(
            child: BlocBuilder<NicknamePageCubit, NicknamePageState>(
              builder: (context, pageState) {
                if (pageState is NicknamePageLoggingOut ||
                    pageState is NicknamePageLoggedOut) {
                  return const LoadingWidget(message: null);
                }
                final isSaving = pageState is NicknamePageSaving;
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(Dimens.spacing24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: Dimens.spacing16),
                      Icon(
                        Icons.alternate_email,
                        size: 56,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: Dimens.spacing16),
                      Text(
                        getString(context, 'nickname_page_heading'),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: Dimens.spacing8),
                      Text(
                        getString(context, 'nickname_page_description'),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(height: Dimens.spacing32),
                      NicknameField(
                        controller: _controller,
                        enabled: !isSaving,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submit(),
                      ),
                      const SizedBox(height: Dimens.spacing32),
                      BlocBuilder<NicknameFieldCubit, NicknameFieldState>(
                        builder: (context, fieldState) => PrimaryButton(
                          text: getString(
                            context,
                            editMode
                                ? 'nickname_page_save'
                                : 'nickname_page_continue',
                          ),
                          isLoading: isSaving,
                          onPressed: fieldState.isAvailable ? _submit : null,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
