import 'package:flutter/material.dart';

import '../../../../../core/design_system/widgets/qeran_empty_state.dart';
import '../../../../../core/design_system/widgets/qeran_error_state.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../generated/locale_keys.g.dart';

/// «منشوراتي» with nothing in it (B4): what she has now, not "you haven't
/// posted yet", which is wrong once she deletes her posts (Q12, as D35).
Widget myPostsEmpty(BuildContext context) => QeranEmptyState(
  icon: Icons.edit_square,
  title: LocaleKeys.matchmaker_community_mine_empty_title.t(context),
  message: LocaleKeys.matchmaker_community_mine_empty_body.t(context),
);

/// «منشوراتي» couldn't load (B5); [retry] asks again.
Widget myPostsError(BuildContext context, VoidCallback retry) =>
    QeranErrorState(
      icon: Icons.cloud_off_rounded,
      title: LocaleKeys.matchmaker_community_mine_error_title.t(context),
      message: LocaleKeys.community_her_feed_error_body.t(context),
      retryLabel: LocaleKeys.community_her_retry.t(context),
      onRetry: retry,
    );
