import 'package:essentials/essentials.dart';
import 'package:flutter/material.dart';

import '../../domain/entity/review.dart';
import '../../domain/entity/review_tag.dart';
import '../bloc/review_form_bloc.dart';
import '../bloc/review_form_event.dart';
import '../bloc/review_form_state.dart';
import 'review_tag_badge.dart';

void showReviewFormSheet(
  BuildContext context, {
  required String wineId,
  required String token,
  Review? existingReview,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => BlocProvider.value(
      value: context.read<ReviewFormBloc>(),
      child: _ReviewFormSheet(
        hostContext: context,
        wineId: wineId,
        token: token,
        existingReview: existingReview,
      ),
    ),
  );
}

class _ReviewFormSheet extends StatefulWidget {
  final BuildContext hostContext;
  final String wineId;
  final String token;
  final Review? existingReview;

  const _ReviewFormSheet({
    required this.hostContext,
    required this.wineId,
    required this.token,
    required this.existingReview,
  });

  @override
  State<_ReviewFormSheet> createState() => _ReviewFormSheetState();
}

class _ReviewFormSheetState extends State<_ReviewFormSheet> {
  late double _nota;
  late List<ReviewTag> _selectedTags;
  List<ReviewTagOption> _availableTags = const [];
  final _comentarioController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nota = widget.existingReview?.nota ?? 7.0;
    _selectedTags =
        List<ReviewTag>.from(widget.existingReview?.tags ?? const []);
    _comentarioController.text = widget.existingReview?.comentario ?? '';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ReviewFormBloc>().add(ReviewFormTagsRequested());
    });
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
            nota: _nota,
            comentario: _comentarioController.text.trim().isEmpty
                ? null
                : _comentarioController.text.trim(),
            tags: _selectedTags,
            token: widget.token,
            reviewId: widget.existingReview?.id,
          ),
        );
  }

  void _toggleTag(ReviewTag tag) {
    if (_selectedTags.contains(tag)) {
      _selectedTags = _selectedTags.where((value) => value != tag).toList();
      return;
    }
    _selectedTags = [..._selectedTags, tag];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdit = widget.existingReview != null;

    return BlocListener<ReviewFormBloc, ReviewFormState>(
      listener: (context, state) {
        if (state is ReviewFormTagsLoaded && mounted) {
          setState(() => _availableTags = state.tags);
        }
        if (state is ReviewFormSuccess &&
            state.operation == ReviewFormOperation.submit) {
          Navigator.of(context).pop();

          if (widget.hostContext.mounted) {
            showVinumSuccessModal(
              widget.hostContext,
              message: 'Sucesso ao enviar sua avaliação!',
            );
          }
        }
        if (state is ReviewFormError &&
            state.operation != ReviewFormOperation.delete) {
          final message = state.message.trim().isEmpty
              ? 'Oops, parece que não foi possível enviar sua avaliação. Tente novamente'
              : state.message;

          showVinumErrorModal(context, message: message);
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
            const SizedBox(height: Dimens.spacing16),
            if (_availableTags.isNotEmpty) ...[
              Text(
                getString(context, 'review_tags'),
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: Dimens.spacing8),
              SizedBox(
                height: Dimens.spacing40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _availableTags.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: Dimens.spacing8),
                  itemBuilder: (context, index) {
                    final tag = _availableTags[index].tag;

                    return ReviewTagBadge(
                      tag: tag,
                      selected: _selectedTags.contains(tag),
                      onTap: () => setState(() => _toggleTag(tag)),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: Dimens.spacing24),
            BlocBuilder<ReviewFormBloc, ReviewFormState>(
              builder: (context, state) {
                return PrimaryButton(
                  text: isEdit ? 'Salvar' : 'Enviar',
                  isLoading: state is ReviewFormLoading &&
                      state.operation == ReviewFormOperation.submit,
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
