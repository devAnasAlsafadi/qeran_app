import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/features/community/domain/entities/community_post.dart';

import '../../../../../core/di/injection_container.dart';
import '../blocs/composer/post_draft_cubit.dart';
import '../blocs/composer/post_publish_cubit.dart';
import 'post_composer_screen.dart';

/// Opens her composer (C1). A plain `MaterialPageRoute` with a × (S10), so
/// iOS keeps its edge swipe while there's nothing to lose. Answers the post
/// she published, or null when she closed it.
Future<CommunityPost?> openPostComposer(BuildContext context) =>
    Navigator.of(context).push<CommunityPost>(
      MaterialPageRoute(builder: (_) => const PostComposerPage()),
    );

/// The composer's draft and its publishing, for the screen below.
class PostComposerPage extends StatelessWidget {
  const PostComposerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<PostDraftCubit>(
          create: (_) => sl<PostDraftCubit>()..loadConfig(),
        ),
        BlocProvider<PostPublishCubit>(create: (_) => sl<PostPublishCubit>()),
      ],
      child: const PostComposerScreen(),
    );
  }
}
