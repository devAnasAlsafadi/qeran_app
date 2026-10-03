import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../core/widgets/paginated_list.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../blocs/feed/community_feed_state.dart';
import '../community_page_error.dart';

/// Under the last post: the next page loading (B8), the next page failed
/// with its retry (B9), or the end of the feed (B10).
class CommunityFeedFooter extends StatelessWidget {
  const CommunityFeedFooter({
    super.key,
    required this.state,
    required this.onRetry,
  });

  final CommunityFeedState state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (state.loadingMore) return const LoadMoreFooter();
    if (state.pageFailed) return CommunityPageError(onRetry: onRetry);
    if (state.reachedEnd) return const _End();
    return const SizedBox.shrink();
  }
}

/// «لا توجد منشورات أخرى» between two hairlines.
class _End extends StatelessWidget {
  const _End();

  @override
  Widget build(BuildContext context) {
    const line = Expanded(
      child: SizedBox(height: 1, child: ColoredBox(color: QeranColors.divider)),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: QeranSpacing.s32,
        vertical: QeranSpacing.s4,
      ),
      child: Row(
        children: [
          line,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: QeranSpacing.s12),
            child: Text(
              LocaleKeys.community_feed_end.t(context),
              style: QeranTypography.caption,
            ),
          ),
          line,
        ],
      ),
    );
  }
}
