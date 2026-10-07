import 'package:qeran/core/domain/upload.dart';

import 'post_draft.dart';

/// One composer's publishing across its attempts (plan §3.4): the request
/// id, the images already uploaded, and the cancel of the attempt in flight.
class PublishSession {
  PublishSession({required String Function() newRequestId})
    : _newRequestId = newRequestId;

  final String Function() _newRequestId;
  final _uploaded = <String, String>{};
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

  /// Every media id this session uploaded.
  List<String> get uploadedIds => List.unmodifiable(_uploaded.values);

  /// Uploads to send again from the start (lost, cancelled, or used).
  void forgetUploads() => _uploaded.clear();
}
