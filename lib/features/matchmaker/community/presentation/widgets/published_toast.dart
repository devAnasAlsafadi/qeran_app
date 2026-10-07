import 'package:flutter/widgets.dart';
import 'package:qeran/features/community/domain/entities/community_post.dart';

import '../../../../../core/enum/snakebar_tybe.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../core/utils/app_snackbar.dart';
import '../../../../../generated/locale_keys.g.dart';

/// Her post made: «تم نشر منشورك.» (D5), or for a video still processing
/// «تم رفع المنشور. يظهر للأعضاء بعد اكتمال معالجة الفيديو.» (D4).
void showPublishedToast(BuildContext context, CommunityPost post) {
  final processing = post.status == CommunityPostStatus.processing;
  AppSnackBar.show(
    context,
    message:
        (processing
                ? LocaleKeys.matchmaker_community_published_processing
                : LocaleKeys.matchmaker_community_published)
            .t(context),
    type: SnackBarType.success,
  );
}
