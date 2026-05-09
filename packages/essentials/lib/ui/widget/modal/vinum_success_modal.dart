import 'package:flutter/material.dart';

import '../icon/vinum_success_icon.dart';
import 'vinum_feedback_modal.dart';

Future<T?> showVinumSuccessModal<T>(
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
    builder: (_) => VinumSuccessModal(
      message: message,
      primaryButtonText: primaryButtonText,
      onPrimaryPressed: onPrimaryPressed,
      closeOnPrimaryAction: closeOnPrimaryAction,
    ),
  );
}

class VinumSuccessModal extends StatelessWidget {
  final String message;
  final String primaryButtonText;
  final VoidCallback? onPrimaryPressed;
  final bool closeOnPrimaryAction;
  final double iconSize;

  const VinumSuccessModal({
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
      icon: VinumSuccessIcon(size: iconSize),
      message: message,
      primaryButtonText: primaryButtonText,
      onPrimaryPressed: onPrimaryPressed,
      closeOnPrimaryAction: closeOnPrimaryAction,
    );
  }
}
