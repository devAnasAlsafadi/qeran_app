import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/widgets/qeran_card.dart';
import '../../../domain/entities/community_media.dart';
import '../../../domain/entities/community_post.dart';
import 'post_card_footer.dart';
import 'post_card_header.dart';
import 'post_card_text.dart';
import 'post_image_set.dart';
import 'post_video_tile.dart';

/// Where a card is shown: in the feed, or at the top of its post screen.
enum CommunityPostCardMode {
  /// Long text is cut at four lines; the discussion half opens the post.
  feed,

  /// The text is whole; the discussion half is a label above the comments.
  detail,
}

/// A matchmaker's post as a card (A1–A21), shared by both apps (P3): header,
/// text, photos or a video, and the Like / discussion footer. The card itself
/// isn't a tap target (S1) — the discussion half, the photos and «عرض
/// المزيد» each do one thing.
class CommunityPostCard extends StatelessWidget {
  const CommunityPostCard({
    super.key,
    required this.post,
    this.mode = CommunityPostCardMode.feed,
    this.readOnly = false,
    this.onLike,
    this.onOpenDiscussion,
    this.onImageTap,
    this.menu,
  });

  final CommunityPost post;
  final CommunityPostCardMode mode;

  /// A member who can read but not take part yet (D9): Like is dimmed.
  final bool readOnly;
  final VoidCallback? onLike;
  final VoidCallback? onOpenDiscussion;
  final ValueChanged<int>? onImageTap;
  final Widget? menu;

  @override
  Widget build(BuildContext context) {
    final feed = mode == CommunityPostCardMode.feed;
    final media = _media();
    return QeranCard(
      padding: EdgeInsets.zero,
      // Ink from the footer's halves paints on the card, clipped to it.
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PostCardHeader(post: post, menu: menu),
            if (post.text.trim().isNotEmpty)
              PostCardText(post.text, collapsible: feed),
            if (media != null) ...[media, QeranSpacing.vs12],
            PostCardFooter(
              post: post,
              interactive: feed,
              likeDimmed: readOnly,
              onLike: onLike,
              onDiscussion: onOpenDiscussion,
            ),
          ],
        ),
      ),
    );
  }

  Widget? _media() => switch (post.media) {
    CommunityNoMedia() => null,
    CommunityImageSet(:final images) => PostImageSet(
      images: images,
      onTap: onImageTap,
    ),
    CommunitySingleVideo(:final video) => PostVideoTile(
      postId: post.id,
      video: video,
    ),
  };
}
