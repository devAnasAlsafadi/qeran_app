/// Payloads shaped exactly like the built server's (contract `03` §2, §4.1,
/// §8; Tariq's `05` §3 and §4.4) — the inner `data` of each envelope.
/// Shared by the model tests now and the datasource tests in 1b.
library;

Map<String, dynamic> matchmakerAuthor() => {
      'id': 'mm-1',
      'displayName': 'هدى',
      'isMatchmaker': true,
      'profileImageUrl': '/api/community/avatars/mm-1',
    };

Map<String, dynamic> memberAuthor() => {
      'id': 'member-7',
      'displayName': 'Sara',
      'isMatchmaker': false,
      'profileImageUrl': null,
    };

Map<String, dynamic> imageMedia({int width = 1080, int height = 1350}) => {
      'type': 'Image',
      'url': '/api/community/media/img-$width',
      'thumbnailUrl': '/api/community/media/img-$width/thumb',
      'width': width,
      'height': height,
      'durationSeconds': null,
      'posterUrl': null,
    };

/// 05 §4.4 — a vertical reel with signed URLs.
Map<String, dynamic> videoMedia({String? url = _signedUrl}) => {
      'type': 'Video',
      'url': url,
      'posterUrl': 'https://vz-1.b-cdn.net/abc/thumbnail.jpg',
      'hlsUrl': 'https://vz-1.b-cdn.net/abc/playlist.m3u8',
      'width': 1080,
      'height': 1920,
      'durationSeconds': 44,
      'urlExpiresAt': '2026-10-01T14:30:00Z',
    };

const _signedUrl =
    'https://vz-1.b-cdn.net/bcdn_token=t&expires=1/abc/play_720p.mp4';

Map<String, dynamic> post({
  int id = 123,
  List<Map<String, dynamic>> media = const [],
  String status = 'Published',
}) =>
    {
      'id': id,
      'author': matchmakerAuthor(),
      'text': 'الاستخارة والاستشارة',
      'media': media,
      'likeCount': 128,
      'likedByMe': false,
      'commentCount': 14,
      'createdAt': '2026-09-30T08:15:00Z',
      'canDelete': false,
      'status': status,
    };

Map<String, dynamic> comment({int id = 456, int? parentCommentId}) => {
      'id': id,
      'postId': 123,
      'parentCommentId': parentCommentId,
      'author': memberAuthor(),
      'text': 'جزاكِ الله خيراً',
      'likeCount': 12,
      'likedByMe': true,
      'replyCount': parentCommentId == null ? 3 : 0,
      'createdAt': '2026-09-30T08:20:00Z',
      'isMine': false,
      'canDelete': false,
      'canBlock': true,
      'flag': null,
    };

Map<String, dynamic> paged(
  List<Map<String, dynamic>> items, {
  int pageNumber = 1,
  int totalPages = 2,
}) =>
    {
      'data': items,
      'pageNumber': pageNumber,
      'pageSize': 20,
      'totalCount': 26,
      'totalPages': totalPages,
    };

/// 05 §3, as built.
Map<String, dynamic> config({bool videoEnabled = true}) => {
      'commentMaxLength': 500,
      'postTextMaxLength': 2000,
      'maxImagesPerPost': 10,
      'maxImageSizeBytes': 5242880,
      'allowedImageTypes': ['jpg', 'jpeg', 'png'],
      'allowedVideoTypes': ['mp4', 'mov'],
      'maxVideoDurationSeconds': 60,
      'maxVideoSizeBytes': 104857600,
      'videoTarget': {'maxHeight': 1280, 'bitrateKbps': 2500, 'codec': 'h264'},
      'videoEnabled': videoEnabled,
    };

/// Contract §4.1 — five sections with Material Symbols names.
Map<String, dynamic> guidelines({
  List<String> icons = const [
    'block',
    'phone_disabled',
    'lock',
    'campaign',
    'flag',
  ],
}) =>
    {
      'version': 3,
      'lastUpdatedAt': '2026-10-01T09:00:00Z',
      'introAr': 'مجتمع قِران مساحة للتعلّم.',
      'introEn': 'Qeran Community is a place to learn.',
      'sections': [
        for (var i = 0; i < icons.length; i++)
          {
            'id': i + 1,
            'icon': icons[i],
            'titleAr': 'قاعدة ${i + 1}',
            'titleEn': 'Rule ${i + 1}',
            'bodyAr': 'نص ${i + 1}',
            'bodyEn': 'Body ${i + 1}',
          },
      ],
    };
