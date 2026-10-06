import 'package:flutter/material.dart';
import 'package:qeran/features/auth/presentation/reader_copy.dart';

import '../../../../../core/design_system/widgets/qeran_empty_state.dart';
import '../../../../../core/design_system/widgets/qeran_error_state.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../generated/locale_keys.g.dart';

/// The feed with no posts at all (B4).
Widget communityFeedEmpty(BuildContext context) => QeranEmptyState(
  icon: Icons.auto_stories_rounded,
  title: LocaleKeys.community_feed_empty_title.t(context),
  message: LocaleKeys.community_feed_empty_body
      .forReader(her: LocaleKeys.community_her_feed_empty_body)
      .t(context),
);

/// The feed's first page failed (B5); [retry] asks again.
Widget communityFeedError(BuildContext context, VoidCallback retry) =>
    QeranErrorState(
      icon: Icons.cloud_off_rounded,
      title: LocaleKeys.community_feed_error_title.t(context),
      message: LocaleKeys.community_feed_error_body
          .forReader(her: LocaleKeys.community_her_feed_error_body)
          .t(context),
      retryLabel: LocaleKeys.community_retry
          .forReader(her: LocaleKeys.community_her_retry)
          .t(context),
      onRetry: retry,
    );
