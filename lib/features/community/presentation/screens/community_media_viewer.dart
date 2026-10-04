import 'package:flutter/material.dart';

import '../../domain/entities/community_media.dart';
import '../video/community_video_controller.dart';
import 'community_image_viewer.dart';
import 'community_video_viewer.dart';

/// A post's photos full screen, from the one tapped (G1). A pushed page, so
/// iOS keeps its edge-swipe back.
Future<void> openCommunityImages(
  BuildContext context, {
  required List<CommunityImage> images,
  required int index,
}) => Navigator.of(context).push(
  MaterialPageRoute<void>(
    builder: (_) => CommunityImageViewer(images: images, initialIndex: index),
  ),
);

/// A card's video full screen (G4, S20): the viewer takes the card's own
/// [controller] — its place kept — and gives it back on close.
Future<void> openCommunityVideo(
  BuildContext context, {
  required CommunityVideoController controller,
  required CommunityVideo video,
}) async {
  controller.handedOver = true;
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) =>
          CommunityVideoViewer(controller: controller, video: video),
    ),
  );
  controller.handedOver = false;
}
