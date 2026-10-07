import 'package:flutter/widgets.dart';

import '../../../../../../core/enum/snakebar_tybe.dart';
import '../../../../../../core/extensions/localization_extension.dart';
import '../../../../../../core/utils/app_snackbar.dart';
import '../../../../../../generated/locale_keys.g.dart';
import '../../blocs/reports/community_reports_state.dart';

/// What she kept or deleted from «البلاغات», or why it didn't go through —
/// the post screen's words (E3, E6, Q11), in her feminine forms.
void showReportsToast(BuildContext context, CommunityReportsEvent event) {
  final (key, type) = _keepToastOf(event);
  if (key == null || type == null) return;
  AppSnackBar.show(context, message: key.t(context), type: type);
}

(String?, SnackBarType?) _keepToastOf(CommunityReportsEvent event) =>
    switch (event) {
      CommunityReportsEvent.kept => (
        LocaleKeys.community_comment_kept,
        SnackBarType.success,
      ),
      CommunityReportsEvent.keptReply => (
        LocaleKeys.community_reply_kept,
        SnackBarType.success,
      ),
      CommunityReportsEvent.keepFailed => (
        LocaleKeys.community_keep_failed,
        SnackBarType.error,
      ),
      _ => _deleteToastOf(event),
    };

(String?, SnackBarType?) _deleteToastOf(CommunityReportsEvent event) =>
    switch (event) {
      CommunityReportsEvent.deleted => (
        LocaleKeys.community_deleted,
        SnackBarType.success,
      ),
      CommunityReportsEvent.deletedReply => (
        LocaleKeys.community_deleted_reply,
        SnackBarType.success,
      ),
      CommunityReportsEvent.deleteFailed => (
        LocaleKeys.community_her_delete_failed,
        SnackBarType.error,
      ),
      CommunityReportsEvent.deleteReplyFailed => (
        LocaleKeys.community_her_delete_reply_failed,
        SnackBarType.error,
      ),
      _ => (null, null),
    };
