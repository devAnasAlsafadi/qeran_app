import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/enum/snakebar_tybe.dart';
import '../../../../core/extensions/localization_extension.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../generated/locale_keys.g.dart';
import '../blocs/post_delete/post_delete_cubit.dart';

/// What her delete of a post says once it's answered (B8, B9): «تم حذف
/// المنشور.» or that it failed, over [child]. On the post's own screen it
/// [leaves] first and says it where she lands (S8).
class PostDeleteListener extends StatelessWidget {
  const PostDeleteListener({
    super.key,
    required this.child,
    this.leaves = false,
  });

  final Widget child;
  final bool leaves;

  static bool _answered(PostDeleteState previous, PostDeleteState current) =>
      previous != current &&
      (current.status == PostDeleteStatus.deleted ||
          current.status == PostDeleteStatus.failed);

  @override
  Widget build(BuildContext context) {
    return BlocListener<PostDeleteCubit, PostDeleteState>(
      listenWhen: _answered,
      listener: _say,
      child: child,
    );
  }

  void _say(BuildContext context, PostDeleteState state) {
    if (state.status == PostDeleteStatus.failed) {
      AppSnackBar.show(
        context,
        message: LocaleKeys.community_delete_post_failed.t(context),
        type: SnackBarType.error,
      );
      return;
    }
    final message = LocaleKeys.community_post_deleted.t(context);
    if (!leaves) {
      AppSnackBar.show(context, message: message, type: SnackBarType.success);
      return;
    }
    Navigator.of(context).maybePop();
    AppSnackBar.showOnRoot(message: message, type: SnackBarType.success);
  }
}
