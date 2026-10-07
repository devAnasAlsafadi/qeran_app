import 'package:qeran/core/errors/exceptions.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/video_upload_grant.dart';
import '../json_parsers.dart';

/// 6.8's `data`: `{ mediaId, upload: { protocol: "tus", endpoint, headers,
/// metadata, expiresAt } }` (contract §6.8). A grant with no id, an
/// endpoint that isn't https, or another protocol is a server fault: the
/// grant's headers authorise the upload, so they never go over plain http.
class VideoUploadGrantModel {
  final String mediaId;
  final Uri endpoint;
  final Map<String, String> headers;
  final Map<String, String> metadata;
  final DateTime? expiresAt;

  const VideoUploadGrantModel({
    required this.mediaId,
    required this.endpoint,
    required this.headers,
    required this.metadata,
    required this.expiresAt,
  });

  factory VideoUploadGrantModel.fromJson(Map<String, dynamic> json) {
    final upload = parseNullableMap(json['upload']) ?? const {};
    final mediaId = parseNullableString(json['mediaId']);
    final endpoint = Uri.tryParse(parseString(upload['endpoint']));
    final protocol = parseNullableString(upload['protocol'])?.toLowerCase();
    if (mediaId == null ||
        endpoint == null ||
        !endpoint.isScheme('https') ||
        (protocol != null && protocol != 'tus')) {
      throw ServerException(message: LocaleKeys.errors_unexpected);
    }
    return VideoUploadGrantModel(
      mediaId: mediaId,
      endpoint: endpoint,
      headers: _strings(upload['headers']),
      metadata: _strings(upload['metadata']),
      expiresAt: parseNullableDateTime(upload['expiresAt']),
    );
  }

  /// Every value as text (`AuthorizationExpire` may come as a number).
  static Map<String, String> _strings(Object? raw) => {
    for (final MapEntry(:key, :value)
        in (parseNullableMap(raw) ?? const {}).entries)
      if (value != null) key: '$value',
  };

  VideoUploadGrant toEntity() => VideoUploadGrant(
    mediaId: mediaId,
    endpoint: endpoint,
    headers: headers,
    metadata: metadata,
    expiresAt: expiresAt,
  );
}
