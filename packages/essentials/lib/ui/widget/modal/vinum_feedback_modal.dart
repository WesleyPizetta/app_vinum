import 'package:flutter/material.dart';

import '../../dimens.dart';
import '../button/primary_button.dart';

class VinumFeedbackModal extends StatelessWidget {
  final Widget icon;
  final String message;
  final String primaryButtonText;
  final VoidCallback? onPrimaryPressed;
  final bool closeOnPrimaryAction;

  const VinumFeedbackModal({
    super.key,
    required this.icon,
    required this.message,
    this.primaryButtonText = 'Fechar',
    this.onPrimaryPressed,
    this.closeOnPrimaryAction = true,
  });

  void _handlePrimaryPressed(BuildContext context) {
    onPrimaryPressed?.call();

    final shouldClose = onPrimaryPressed == null || closeOnPrimaryAction;
    final isDialogStillCurrent = ModalRoute.of(context)?.isCurrent ?? false;

    if (shouldClose && isDialogStillCurrent && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: Dimens.spacing24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimens.radiusLarge),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Dimens.spacing20,
            Dimens.spacing20,
            Dimens.spacing20,
            Dimens.spacing16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.center,
                child: icon,
              ),
              const SizedBox(height: Dimens.spacing20),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: Dimens.spacing24),
              PrimaryButton(
                text: primaryButtonText,
                onPressed: () => _handlePrimaryPressed(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
