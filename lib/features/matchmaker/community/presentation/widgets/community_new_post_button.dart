import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/features/community/presentation/blocs/feed/community_feed_state.dart';

import '../../../../../core/design_system/widgets/qeran_floating_button.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../blocs/my_posts/my_posts_cubit.dart';

/// «منشور جديد» floating at the end of her Community screen (B1) — except
/// over an empty «منشوراتي», whose own «منشور جديد» stands in the middle
/// (B4).
class CommunityNewPostButton extends StatelessWidget {
  const CommunityNewPostButton({
    super.key,
    required this.mine,
    required this.onMine,
    required this.onPressed,
  });

  final MyPostsCubit mine;

  /// «منشوراتي» is the segment on screen.
  final bool onMine;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MyPostsCubit, CommunityFeedState>(
      bloc: mine,
      buildWhen: (previous, current) => previous.status != current.status,
      builder: (context, state) {
        if (onMine && state.status == CommunityFeedStatus.empty) {
          return const SizedBox.shrink();
        }
        return QeranFloatingButton(
          label: LocaleKeys.matchmaker_community_new_post.t(context),
          icon: Icons.edit_square,
          onPressed: onPressed,
        );
      },
    );
  }
}
