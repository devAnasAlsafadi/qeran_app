import 'package:equatable/equatable.dart';
import 'package:qeran/features/community/domain/entities/community_config.dart';
import 'package:qeran/features/community/domain/entities/picked_image.dart';
import 'package:qeran/features/community/domain/entities/picked_video.dart';

/// Why her last media pick didn't all go in; it stands until her next one.
sealed class DraftNotice extends Equatable {
  const DraftNotice();

  @override
  List<Object?> get props => [];
}

/// More picked than free slots (C8): the first [added] of [picked] went in;
/// a post takes [limit].
final class TooManyImages extends DraftNotice {
  final int added;
  final int picked;
  final int limit;
  const TooManyImages({
    required this.added,
    required this.picked,
    required this.limit,
  });

  @override
  List<Object?> get props => [added, picked, limit];
}

/// Not a type the server takes (C10).
final class UnsupportedFile extends DraftNotice {
  const UnsupportedFile();
}

/// Over config's `maxImageSizeBytes` (Q3).
final class ImageTooLarge extends DraftNotice {
  final int sizeBytes;
  final int maxBytes;
  const ImageTooLarge({required this.sizeBytes, required this.maxBytes});

  @override
  List<Object?> get props => [sizeBytes, maxBytes];
}

/// Longer than config's `maxVideoDurationSeconds` (BA-A9), checked on the
/// file before anything is compressed or sent.
final class VideoTooLong extends DraftNotice {
  final int seconds;
  final int maxSeconds;
  const VideoTooLong({required this.seconds, required this.maxSeconds});

  @override
  List<Object?> get props => [seconds, maxSeconds];
}

/// Over config's `maxVideoSizeBytes` (Q3): the file that would have gone
/// up, compressed or not.
final class VideoTooLarge extends DraftNotice {
  final int sizeBytes;
  final int maxBytes;
  const VideoTooLarge({required this.sizeBytes, required this.maxBytes});

  @override
  List<Object?> get props => [sizeBytes, maxBytes];
}

/// Her draft as it stands (C1–C11, BA-A7).
class PostDraftState extends Equatable {
  const PostDraftState({
    this.text = '',
    this.config,
    this.rejected = false,
    this.images = const [],
    this.video,
    this.notice,
  });

  final String text;

  /// The server's limits, read fresh when the composer opens (K20); null
  /// until then, or when they couldn't be read — the server checks then
  /// (S19).
  final CommunityConfig? config;

  /// The filter refused the text as it stands (BA-A7); gone once she edits.
  final bool rejected;

  /// Her images in her order (C5), or one video (C6): never both (D11).
  final List<PickedImage> images;
  final PickedVideo? video;
  final DraftNotice? notice;

  int? get maxLength => config?.postTextMaxLength;

  /// UTF-16 code units after trimming, as the server counts (contract §6.2).
  int get length => text.trim().length;

  bool get tooLong => length > (maxLength ?? length);

  /// «نشر» turns on: some text, within the limit. Media never stands in for
  /// text (contract §6.2).
  bool get canPublish => length > 0 && !tooLong;

  /// Nothing to lose: × closes at once (C11).
  bool get isEmpty => length == 0 && images.isEmpty && video == null;

  /// The server offers video now (BA-A4): read fresh, false unless it says.
  bool get videoOffered => config?.videoEnabled ?? false;

  int? get maxVideoSeconds => config?.maxVideoDurationSeconds;

  /// Images while there's no video and room for more (C5, C6).
  bool get canAddImages => video == null && !imagesFull;

  /// One video, offered, on a draft with no media yet (C5, C6, D11).
  bool get canAddVideo => videoOffered && video == null && images.isEmpty;

  int? get maxImages => config?.maxImagesPerPost;

  /// How many more images fit; null when config didn't say (the server
  /// checks then).
  int? get freeImageSlots {
    final max = maxImages;
    return max == null ? null : (max - images.length).clamp(0, max);
  }

  bool get imagesFull => freeImageSlots == 0;

  PostDraftState copyWith({
    String? text,
    CommunityConfig? config,
    bool? rejected,
    List<PickedImage>? images,
    PickedVideo? Function()? video,
    DraftNotice? Function()? notice,
  }) => PostDraftState(
    text: text ?? this.text,
    config: config ?? this.config,
    rejected: rejected ?? this.rejected,
    images: images ?? this.images,
    video: video == null ? this.video : video(),
    notice: notice == null ? this.notice : notice(),
  );

  @override
  List<Object?> get props => [text, config, rejected, images, video, notice];
}
