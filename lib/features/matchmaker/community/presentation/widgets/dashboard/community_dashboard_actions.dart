import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../../core/design_system/widgets/qeran_button.dart';
import '../../../../../../core/extensions/localization_extension.dart';
import '../../../../../../generated/locale_keys.g.dart';
import '../../screens/matchmaker_community_screen.dart';
import '../../screens/start_new_post.dart';
import '../published_toast.dart';

/// Under the Community card's rows (A2): «المجتمع» to the feed, and «منشور
/// جديد». Published from here, she lands on «منشوراتي» with her post first,
/// and back returns to the Dashboard (Q7).
class CommunityDashboardActions extends StatelessWidget {
  const CommunityDashboardActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: QeranButton(
            label: LocaleKeys.matchmaker_community_title.t(context),
            onPressed: () => unawaited(openMatchmakerCommunity(context)),
            variant: QeranButtonVariant.secondary,
            size: QeranButtonSize.compact,
            leadingIcon: Icons.dynamic_feed_rounded,
          ),
        ),
        QeranSpacing.hs8,
        Expanded(
          child: QeranButton(
            label: LocaleKeys.matchmaker_community_new_post.t(context),
            onPressed: () => _newPost(context),
            variant: QeranButtonVariant.primaryGold,
            size: QeranButtonSize.compact,
            leadingIcon: Icons.edit_square,
          ),
        ),
      ],
    );
  }

  static Future<void> _newPost(BuildContext context) async {
    final post = await startNewPost(context);
    if (post == null || !context.mounted) return;
    unawaited(
      openMatchmakerCommunity(context, tab: MatchmakerCommunityTab.mine),
    );
    showPublishedToast(context, post);
  }
}
