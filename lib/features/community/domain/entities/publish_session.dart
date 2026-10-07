import 'package:qeran/core/domain/upload.dart';

import 'picked_video.dart';
import 'post_draft.dart';
import 'video_upload_grant.dart';

/// One composer's publishing across its attempts (plan §3.4): the request
/// id, the images already uploaded, her video made ready, and the cancel of
/// the attempt in flight.
class PublishSession {
  PublishSession({required String Function() newRequestId})
    : _newRequestId = newRequestId;

  final String Function() _newRequestId;
  final _uploaded = <String, String>{};
  final _prepared = <String, PickedVideo>{};
  VideoUploadRecord? _video;
  String? _requestKey;
  String? _requestId;
  UploadCancel? _cancel;

  /// The same id while the draft is what went out last — so a retry after
  /// a lost answer returns the post that was made, never a second (W16) —
  /// and a new one once she changes it.
  String requestIdFor(PostDraft draft) {
    if (draft.key != _requestKey || _requestId == null) {
      _requestKey = draft.key;
      _requestId = _newRequestId();
    }
    return _requestId!;
  }

  /// A new attempt: its own cancel.
  UploadCancel begin() => _cancel = UploadCancel();

  /// Stops the attempt in flight, if any.
  void cancel() => _cancel?.cancel();

  /// The image at [path] went up as [mediaId]; a retry doesn't send it again.
  void remember(String path, String mediaId) => _uploaded[path] = mediaId;

  String? uploadedId(String path) => _uploaded[path];

  /// Every media id this session uploaded, or was granted for her video.
  List<String> get uploadedIds =>
      List.unmodifiable([..._uploaded.values, ?_video?.grant.mediaId]);

  /// Uploads to send again from the start (lost, cancelled, or used).
  void forgetUploads() {
    _uploaded.clear();
    _video = null;
  }

  /// Her video's upload so far, whichever file it was for.
  VideoUploadRecord? get pendingVideo => _video;

  /// 6.8 granted [grant] for the file at [path]: its upload starts there.
  VideoUploadRecord rememberGrant(String path, VideoUploadGrant grant) =>
      _video = VideoUploadRecord(path, grant);

  void forgetVideo() => _video = null;

  /// Her video at [path] made ready as [file] (compressed, or the original
  /// when it couldn't be, Q2): a retry doesn't compress it again.
  void rememberPrepared(String path, PickedVideo file) =>
      _prepared[path] = file;

  PickedVideo? preparedVideo(String path) => _prepared[path];
}

/// Her video's upload so far (plan §3.4): 6.8's grant for the file at
/// [path], tus's upload URL once Bunny made one, and whether all of the
/// file is there. Retry goes on from Bunny's offset at [uploadUrl] (D3).
class VideoUploadRecord {
  VideoUploadRecord(this.path, this.grant);

  final String path;
  final VideoUploadGrant grant;
  Uri? uploadUrl;
  bool complete = false;
}
