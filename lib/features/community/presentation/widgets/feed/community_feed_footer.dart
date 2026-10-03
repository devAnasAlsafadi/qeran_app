import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../../core/design_system/widgets/qeran_button.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../core/widgets/paginated_list.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../blocs/feed/community_feed_state.dart';

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
    if (state.pageFailed) return _PageFailed(onRetry: onRetry);
    if (state.reachedEnd) return const _End();
    return const SizedBox.shrink();
  }
}

class _PageFailed extends StatelessWidget {
  const _PageFailed({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: QeranSpacing.s16),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: QeranSpacing.s4,
        children: [
          Text(
            LocaleKeys.community_feed_page_error.t(context),
            style: QeranTypography.bodySm.copyWith(color: QeranColors.inkMuted),
          ),
          QeranButton(
            label: LocaleKeys.community_feed_retry.t(context),
            onPressed: onRetry,
            variant: QeranButtonVariant.ghost,
            size: QeranButtonSize.compact,
            leadingIcon: Icons.refresh_rounded,
            fullWidth: false,
          ),
        ],
      ),
    );
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
