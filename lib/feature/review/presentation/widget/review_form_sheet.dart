import 'package:essentials/essentials.dart';
import 'package:flutter/material.dart';

import '../../domain/entity/review.dart';
import '../bloc/review_form_bloc.dart';
import '../bloc/review_form_event.dart';
import '../bloc/review_form_state.dart';

void showReviewFormSheet(
  BuildContext context, {
  required String wineId,
  required String usuarioId,
  required String token,
  Review? existingReview,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => BlocProvider.value(
      value: context.read<ReviewFormBloc>(),
      child: _ReviewFormSheet(
        wineId: wineId,
        usuarioId: usuarioId,
        token: token,
        existingReview: existingReview,
      ),
    ),
  );
}

class _ReviewFormSheet extends StatefulWidget {
  final String wineId;
  final String usuarioId;
  final String token;
  final Review? existingReview;

  const _ReviewFormSheet({
    required this.wineId,
    required this.usuarioId,
    required this.token,
    required this.existingReview,
  });

  @override
  State<_ReviewFormSheet> createState() => _ReviewFormSheetState();
}

class _ReviewFormSheetState extends State<_ReviewFormSheet> {
  late double _nota;
  final _comentarioController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nota = widget.existingReview?.nota ?? 7.0;
    _comentarioController.text = widget.existingReview?.comentario ?? '';
  }

  @override
  void dispose() {
    _comentarioController.dispose();
    super.dispose();
  }

  void _submit() {
    context.read<ReviewFormBloc>().add(
          ReviewFormSubmitted(
            wineId: widget.wineId,
            usuarioId: widget.usuarioId,
            nota: _nota,
            comentario: _comentarioController.text.trim().isEmpty
                ? null
                : _comentarioController.text.trim(),
            token: widget.token,
            reviewId: widget.existingReview?.id,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdit = widget.existingReview != null;

    return BlocListener<ReviewFormBloc, ReviewFormState>(
      listener: (context, state) {
        if (state is ReviewFormSuccess) {
          Navigator.of(context).pop();
        }
      },
      child: Padding(
        padding: EdgeInsets.only(
          left: Dimens.spacing24,
          right: Dimens.spacing24,
          top: Dimens.spacing24,
          bottom: MediaQuery.of(context).viewInsets.bottom + Dimens.spacing24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isEdit ? 'Editar avaliação' : 'Nova avaliação',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: Dimens.spacing24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Nota', style: theme.textTheme.bodyLarge),
                Text(
                  _nota.toStringAsFixed(1),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Slider(
              value: _nota,
              min: 0,
              max: 10,
              divisions: 20,
              onChanged: (v) => setState(() => _nota = v),
            ),
            const SizedBox(height: Dimens.spacing16),
            TextField(
              controller: _comentarioController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Comentário (opcional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: Dimens.spacing24),
            BlocBuilder<ReviewFormBloc, ReviewFormState>(
              builder: (context, state) {
                if (state is ReviewFormError) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        state.message,
                        style: TextStyle(color: theme.colorScheme.error),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: Dimens.spacing8),
                      PrimaryButton(
                        text: isEdit ? 'Salvar' : 'Enviar',
                        onPressed: _submit,
                      ),
                    ],
                  );
                }
                return PrimaryButton(
                  text: isEdit ? 'Salvar' : 'Enviar',
                  isLoading: state is ReviewFormLoading,
                  onPressed: _submit,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
