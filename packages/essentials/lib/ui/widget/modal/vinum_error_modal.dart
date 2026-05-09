import 'package:flutter/material.dart';

import '../icon/vinum_error_icon.dart';
import 'vinum_feedback_modal.dart';

Future<T?> showVinumErrorModal<T>(
  BuildContext context, {
  required String message,
  String primaryButtonText = 'Fechar',
  VoidCallback? onPrimaryPressed,
  bool closeOnPrimaryAction = true,
  bool barrierDismissible = true,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (_) => VinumErrorModal(
      message: message,
      primaryButtonText: primaryButtonText,
      onPrimaryPressed: onPrimaryPressed,
      closeOnPrimaryAction: closeOnPrimaryAction,
    ),
  );
}

class VinumErrorModal extends StatelessWidget {
  final String message;
  final String primaryButtonText;
  final VoidCallback? onPrimaryPressed;
  final bool closeOnPrimaryAction;
  final double iconSize;

  const VinumErrorModal({
    super.key,
    required this.message,
    this.primaryButtonText = 'Fechar',
    this.onPrimaryPressed,
    this.closeOnPrimaryAction = true,
    this.iconSize = 80,
  });

  @override
  Widget build(BuildContext context) {
    return VinumFeedbackModal(
      icon: VinumErrorIcon(size: iconSize),
      message: message,
      primaryButtonText: primaryButtonText,
      onPrimaryPressed: onPrimaryPressed,
      closeOnPrimaryAction: closeOnPrimaryAction,
    );
  }
}
