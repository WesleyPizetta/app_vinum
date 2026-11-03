import 'package:essentials/essentials.dart';
import 'package:flutter/material.dart';

import '../../../../core/utils/relative_time.dart';
import '../../domain/entity/review.dart';
import '../bloc/review_form_bloc.dart';
import '../bloc/review_form_event.dart';
import 'review_form_sheet.dart';
import 'review_tag_badge.dart';

class ReviewCard extends StatelessWidget {
  final Review review;
  final String wineId;
  final String? currentUserId;
  final String? currentToken;

  const ReviewCard({
    super.key,
    required this.review,
    required this.wineId,
    this.currentUserId,
    this.currentToken,
  });

  bool get _isOwner =>
      currentUserId != null && currentUserId == review.usuarioId;

  String get _authorLabel {
    if (_isOwner) {
      return 'Você';
    }

    // `usuario_nome` agora é o apelido do autor ("" quando não definido).
    var nickname = review.usuarioNome?.trim() ?? '';
    if (nickname.startsWith('@')) nickname = nickname.substring(1).trim();
    // Privacidade: apelidos nunca têm "@"; algo assim pode ser e-mail.
    if (nickname.isNotEmpty && !nickname.contains('@')) {
      return '@$nickname';
    }

    return 'Usuário';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final createdAt = review.createdAt.toLocal();
    final timeAgo = relativeTimeLabel(context, createdAt);
    final fullDate = DateFormat('dd/MM/yyyy HH:mm').format(createdAt);

    return Card(
      margin: const EdgeInsets.only(bottom: Dimens.spacing8),
      child: Padding(
        padding: const EdgeInsets.all(Dimens.spacing12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _RatingBadge(nota: review.nota),
                const SizedBox(width: Dimens.spacing8),
                Expanded(
                  child: Text(
                    _authorLabel,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Tooltip(
                  message: fullDate,
                  child: Text(timeAgo, style: theme.textTheme.labelSmall),
                ),
                if (_isOwner && currentToken != null) ...[
                  const SizedBox(width: Dimens.spacing4),
                  _OwnerActions(
                    review: review,
                    wineId: wineId,
                    token: currentToken!,
                  ),
                ],
              ],
            ),
            if (review.comentario != null && review.comentario!.isNotEmpty) ...[
              const SizedBox(height: Dimens.spacing8),
              Text(review.comentario!, style: theme.textTheme.bodyMedium),
            ],
            if (review.tags.isNotEmpty) ...[
              const SizedBox(height: Dimens.spacing8),
              Wrap(
                spacing: Dimens.spacing8,
                runSpacing: Dimens.spacing8,
                children: review.tags
                    .map(
                      (tag) => ReviewTagBadge(
                        tag: tag,
                        selected: true,
                        compact: true,
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RatingBadge extends StatelessWidget {
  final double nota;
  const _RatingBadge({required this.nota});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimens.spacing8,
        vertical: Dimens.spacing4,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(Dimens.spacing8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded,
              size: 14, color: theme.colorScheme.onPrimary),
          const SizedBox(width: 2),
          Text(
            nota.toStringAsFixed(1),
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _OwnerActions extends StatelessWidget {
  final Review review;
  final String wineId;
  final String token;

  const _OwnerActions({
    required this.review,
    required this.wineId,
    required this.token,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_Action>(
      icon: const Icon(Icons.more_vert, size: 18),
      padding: EdgeInsets.zero,
      onSelected: (action) {
        switch (action) {
          case _Action.edit:
            showReviewFormSheet(
              context,
              wineId: wineId,
              token: token,
              existingReview: review,
            );
          case _Action.delete:
            _confirmDelete(context);
        }
      },
      itemBuilder: (_) => const [
        PopupMenuItem(value: _Action.edit, child: Text('Editar')),
        PopupMenuItem(value: _Action.delete, child: Text('Excluir')),
      ],
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Excluir avaliação'),
        content: const Text('Tem certeza que deseja excluir esta avaliação?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              context.read<ReviewFormBloc>().add(
                    ReviewFormDeleted(reviewId: review.id, token: token),
                  );
            },
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }
}

enum _Action { edit, delete }
