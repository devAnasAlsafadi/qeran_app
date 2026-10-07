import 'package:equatable/equatable.dart';

/// 6.8's answer (plan §3.4): her video's media id, and where and how its
/// file goes to Bunny Stream with tus — [headers] on every request,
/// [metadata] on the create. Valid until [expiresAt] (24 h); null when the
/// server didn't say.
class VideoUploadGrant extends Equatable {
  final String mediaId;
  final Uri endpoint;
  final Map<String, String> headers;
  final Map<String, String> metadata;
  final DateTime? expiresAt;

  const VideoUploadGrant({
    required this.mediaId,
    required this.endpoint,
    this.headers = const {},
    this.metadata = const {},
    this.expiresAt,
  });

  @override
  List<Object?> get props => [mediaId, endpoint, headers, metadata, expiresAt];
}
