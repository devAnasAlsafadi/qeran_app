import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/design_system/tokens/qeran_motion.dart';
import '../../blocs/comments/community_comments_cubit.dart';
import '../../blocs/comments/community_comments_state.dart';

/// Around «النقاش»: once a landing has landed (C8), scrolls it to the top —
/// the thread the notification is about is first under it — and lets its
/// highlight go [highlightFor] later (S7). Once per screen.
class CommentsLandingReveal extends StatefulWidget {
  const CommentsLandingReveal({super.key, required this.child});

  final Widget child;

  /// How long the row stays in gold once it's in view.
  static const Duration highlightFor = Duration(seconds: 2);

  @override
  State<CommentsLandingReveal> createState() => _CommentsLandingRevealState();
}

class _CommentsLandingRevealState extends State<CommentsLandingReveal> {
  Timer? _fade;

  @override
  void initState() {
    super.initState();
    _reveal(context.read<CommunityCommentsCubit>().state);
  }

  /// Comments that landed before the post was here are revealed as soon as
  /// it is; those that land after it, when they do.
  void _reveal(CommunityCommentsState state) {
    if (state.highlightId == null || _fade != null) return;
    final cubit = context.read<CommunityCommentsCubit>();
    _fade = Timer(CommentsLandingReveal.highlightFor, cubit.clearHighlight);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Scrollable.ensureVisible(
        context,
        duration: QeranMotion.standard,
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _fade?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CommunityCommentsCubit, CommunityCommentsState>(
      listenWhen: (previous, current) =>
          previous.highlightId != current.highlightId,
      listener: (_, state) => _reveal(state),
      child: widget.child,
    );
  }
}
