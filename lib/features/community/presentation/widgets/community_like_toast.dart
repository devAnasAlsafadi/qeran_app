import 'package:flutter/widgets.dart';

import '../../../../core/enum/snakebar_tybe.dart';
import '../../../../core/extensions/localization_extension.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../generated/locale_keys.g.dart';

/// The toast after a like that didn't go through, on a post or a comment:
/// why, for a member who can't take part yet ([readOnly], B12, D9) — a
/// calm notice; otherwise that it didn't save (B13).
void showCommunityLikeToast(BuildContext context, {required bool readOnly}) {
  final (key, type) = readOnly
      ? (LocaleKeys.community_read_only_like, SnackBarType.notice)
      : (LocaleKeys.community_like_failed, SnackBarType.error);
  AppSnackBar.show(context, message: key.t(context), type: type);
}
