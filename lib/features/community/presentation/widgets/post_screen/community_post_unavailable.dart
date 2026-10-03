import 'package:flutter/material.dart';

import '../../../../../core/design_system/widgets/qeran_empty_state.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../generated/locale_keys.g.dart';

/// The post was deleted, or this member can no longer see it (C7): why, and
/// «العودة إلى المجتمع».
class CommunityPostUnavailable extends StatelessWidget {
  const CommunityPostUnavailable({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return QeranEmptyState(
      icon: Icons.article_outlined,
      title: LocaleKeys.community_post_unavailable_title.t(context),
      message: LocaleKeys.community_post_unavailable_body.t(context),
      actionLabel: LocaleKeys.community_back_to_community.t(context),
      onAction: onBack,
    );
  }
}
