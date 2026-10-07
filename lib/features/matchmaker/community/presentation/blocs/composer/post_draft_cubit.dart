import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/state/safe_emit.dart';
import 'package:qeran/features/community/domain/entities/media_refusal.dart';
import 'package:qeran/features/community/domain/entities/picked_image.dart';
import 'package:qeran/features/community/domain/entities/picked_video.dart';
import 'package:qeran/features/community/domain/usecases/get_community_config_usecase.dart';
import 'package:qeran/features/community/domain/usecases/inspect_picked_image_usecase.dart';
import 'package:qeran/features/community/domain/usecases/inspect_picked_video_usecase.dart';

import 'post_draft_state.dart';

export 'post_draft_state.dart';

/// Her draft (C1–C11): the text, her images or video, and the limits they
/// are checked against.
class PostDraftCubit extends Cubit<PostDraftState>
    with SafeEmit<PostDraftState> {
  PostDraftCubit({
    required GetCommunityConfigUseCase getConfig,
    required InspectPickedImageUseCase inspectImage,
    required InspectPickedVideoUseCase inspectVideo,
  }) : _getConfig = getConfig,
       _inspectImage = inspectImage,
       _inspectVideo = inspectVideo,
       super(const PostDraftState());

  final GetCommunityConfigUseCase _getConfig;
  final InspectPickedImageUseCase _inspectImage;
  final InspectPickedVideoUseCase _inspectVideo;

  /// The limits as the server has them now.
  Future<void> loadConfig() async {
    final result = await _getConfig(fresh: true);
    result.fold((_) {}, (config) => emit(state.copyWith(config: config)));
  }

  /// She typed: a refusal no longer applies to what's there.
  void edit(String text) {
    if (text == state.text) return;
    emit(state.copyWith(text: text, rejected: false));
  }

  /// The filter refused the text (BA-A7).
  void refused() => emit(state.copyWith(rejected: true));

  /// What she picked, in her order: each file checked by its bytes and
  /// config's types and size, then as many as fit (C8, C10, Q3).
  Future<void> addImages(List<String> paths) async {
    if (paths.isEmpty) return;
    final inspected = await Future.wait(paths.map(_inspectImage.call));
    final accepted = <PickedImage>[];
    DraftNotice? refusal;
    for (final image in inspected) {
      final problem = _problemWith(image);
      if (problem == null) {
        accepted.add(image!);
      } else {
        refusal ??= problem;
      }
    }
    final free = state.freeImageSlots ?? accepted.length;
    emit(
      state.copyWith(
        images: [...state.images, ...accepted.take(free)],
        notice: () => refusal ?? _tooMany(accepted.length, free, paths.length),
      ),
    );
  }

  /// Her video, read from the file before anything is sent: a type the
  /// server wouldn't take (C10) or a length over the limit (BA-A9) stays
  /// out, and the notice says why.
  Future<void> addVideo(String path) async {
    final video = await _inspectVideo(path);
    final problem = _videoProblem(video);
    emit(
      state.copyWith(
        video: () => problem == null ? video : state.video,
        notice: () => problem,
      ),
    );
  }

  void removeVideo() =>
      emit(state.copyWith(video: () => null, notice: () => null));

  void removeImage(int index) => emit(
    state.copyWith(
      images: [...state.images]..removeAt(index),
      notice: () => null,
    ),
  );

  /// Her new order: the image at [from] now sits at [to].
  void moveImage(int from, int to) {
    final images = [...state.images];
    images.insert(to, images.removeAt(from));
    emit(state.copyWith(images: images));
  }

  /// Her media was refused after the app's checks at pick — by the server,
  /// or her video by its size once prepared: it leaves the draft, and the
  /// notice says why (Q3, C10). [sizeBytes] is the video file's.
  void mediaRefused({
    required String? path,
    required MediaRefusal refusal,
    int? sizeBytes,
  }) {
    final video = state.video;
    if (video != null && video.path == path) {
      return _videoRefused(refusal, sizeBytes ?? video.info.sizeBytes);
    }
    final image = state.images.where((i) => i.path == path).firstOrNull;
    final max = state.config?.maxImageSizeBytes;
    emit(
      state.copyWith(
        images: [...state.images]..remove(image),
        notice: () =>
            refusal == MediaRefusal.tooLarge && image != null && max != null
            ? ImageTooLarge(sizeBytes: image.sizeBytes, maxBytes: max)
            : const UnsupportedFile(),
      ),
    );
  }

  void _videoRefused(MediaRefusal refusal, int sizeBytes) {
    final max = state.config?.maxVideoSizeBytes;
    emit(
      state.copyWith(
        video: () => null,
        notice: () => refusal == MediaRefusal.tooLarge && max != null
            ? VideoTooLarge(sizeBytes: sizeBytes, maxBytes: max)
            : const UnsupportedFile(),
      ),
    );
  }

  DraftNotice? _videoProblem(PickedVideo? video) {
    final types = state.config?.allowedVideoTypes ?? const [];
    if (video == null ||
        (types.isNotEmpty && !video.container.allowedBy(types))) {
      return const UnsupportedFile();
    }
    final max = state.maxVideoSeconds;
    if (max != null && video.durationSeconds > max) {
      return VideoTooLong(seconds: video.durationSeconds, maxSeconds: max);
    }
    return null;
  }

  DraftNotice? _problemWith(PickedImage? image) {
    final config = state.config;
    final types = config?.allowedImageTypes ?? const [];
    if (image == null || (types.isNotEmpty && !image.format.allowedBy(types))) {
      return const UnsupportedFile();
    }
    final max = config?.maxImageSizeBytes;
    if (max != null && image.sizeBytes > max) {
      return ImageTooLarge(sizeBytes: image.sizeBytes, maxBytes: max);
    }
    return null;
  }

  /// C8: more fit than were free. It names the post's limit.
  DraftNotice? _tooMany(int accepted, int free, int picked) => accepted > free
      ? TooManyImages(
          added: free,
          picked: picked,
          limit: state.maxImages ?? free,
        )
      : null;
}
