import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../../core/design_system/widgets/qeran_button.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../../domain/entities/community_post.dart';
import '../menus/community_post_menu.dart';

/// The top of her post while members can't see it — only its author ever
/// receives one (contract §2.2): «قيد المعالجة» while the video encodes
/// (D4), or «تعذّرت معالجة الفيديو» with its Delete once it failed (BA-A1).
/// Nothing for a published post.
class PostCardStatusBanner extends StatelessWidget {
  const PostCardStatusBanner({super.key, required this.post});

  final CommunityPost post;

  @override
  Widget build(BuildContext context) => switch (post.status) {
    CommunityPostStatus.processing => const _Processing(),
    CommunityPostStatus.failed => _Failed(post: post),
    CommunityPostStatus.published ||
    CommunityPostStatus.unknown => const SizedBox.shrink(),
  };
}

class _Processing extends StatelessWidget {
  const _Processing();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 36),
      padding: const EdgeInsets.symmetric(
        horizontal: QeranSpacing.s16,
        vertical: QeranSpacing.s6,
      ),
      decoration: const BoxDecoration(
        color: QeranColors.gold12,
        border: Border(bottom: BorderSide(color: QeranColors.gold40)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.hourglass_top_rounded,
            size: 16,
            color: QeranColors.goldDeep,
          ),
          const SizedBox(width: QeranSpacing.s6),
          Expanded(
            child: Text(
              LocaleKeys.community_status_processing.t(context),
              style: QeranTypography.label.copyWith(
                color: QeranColors.goldDeep,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Failed extends StatelessWidget {
  const _Failed({required this.post});

  final CommunityPost post;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      color: QeranColors.danger12,
      padding: const EdgeInsetsDirectional.fromSTEB(
        QeranSpacing.s16,
        QeranSpacing.s8,
        QeranSpacing.s8,
        QeranSpacing.s8,
      ),
      child: Row(
        children: [
          const Icon(Icons.error_rounded, size: 20, color: QeranColors.danger),
          QeranSpacing.hs8,
          Expanded(child: _words(context)),
          QeranButton(
            label: LocaleKeys.common_delete.t(context),
            onPressed: () => deleteOwnPost(context, post),
            variant: QeranButtonVariant.destructive,
            size: QeranButtonSize.compact,
            leadingIcon: Icons.delete_outline_rounded,
            fullWidth: false,
          ),
        ],
      ),
    );
  }

  Widget _words(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        LocaleKeys.community_status_failed.t(context),
        style: QeranTypography.label.copyWith(color: QeranColors.danger),
      ),
      Text(
        LocaleKeys.community_status_failed_body.t(context),
        style: QeranTypography.caption.copyWith(color: QeranColors.danger),
      ),
    ],
  );
}
