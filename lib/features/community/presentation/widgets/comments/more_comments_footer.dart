import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/widgets/qeran_button.dart';
import '../../../../../core/design_system/widgets/qeran_loader.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../blocs/comments/community_comments_state.dart';
import '../community_page_error.dart';

/// Under the last comment (C3): «عرض تعليقات أخرى» while the server has
/// more, a loader while they come, or the page error with its retry.
class MoreCommentsFooter extends StatelessWidget {
  const MoreCommentsFooter({
    super.key,
    required this.state,
    required this.onMore,
  });

  final CommunityCommentsState state;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    if (state.loadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: QeranSpacing.s12),
        child: Center(child: QeranLoader(size: 24)),
      );
    }
    if (state.pageFailed) return CommunityPageError(onRetry: onMore);
    if (!state.hasMore) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: QeranSpacing.s6),
      // A Row, so the button hugs its label instead of filling the width.
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          QeranButton(
            label: LocaleKeys.community_more_comments.t(context),
            onPressed: onMore,
            variant: QeranButtonVariant.secondary,
            size: QeranButtonSize.compact,
            fullWidth: false,
          ),
        ],
      ),
    );
  }
}
