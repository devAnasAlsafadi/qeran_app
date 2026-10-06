import 'package:qeran/features/community/domain/entities/community_author.dart';
import 'package:qeran/features/community/domain/entities/community_media.dart';
import 'package:qeran/features/community/domain/entities/community_post.dart';

/// Entities for widget tests, with the boards' people and texts.

const huda = CommunityAuthor(
  id: 'mm-1',
  displayName: 'هدى العتيبي',
  isMatchmaker: true,
);

const nouraWithPhoto = CommunityAuthor(
  id: 'mm-2',
  displayName: 'نورة الدوسري',
  isMatchmaker: true,
  profileImageUrl: '/api/community/avatars/mm-2',
);

const ummAbdulrahman = CommunityAuthor(
  id: 'mm-3',
  displayName: 'أم عبدالرحمن الشمّري',
  isMatchmaker: true,
);

const istikhara =
    'الاستخارة لا تعني انتظار رؤيا أو علامة. صلِّ ركعتين وادعُ '
    'بدعاء الاستخارة، ثم امضِ في الأمر بالأسباب المعتادة.';

const englishText =
    'A reminder: being accurate in your details from the '
    'start saves both sides a lot.';

/// Long enough to pass four lines at any card width.
final longText = List.filled(12, istikhara).join(' ');

CommunityImage testImage({
  int width = 1080,
  int height = 1350,
  String url = '/api/community/media/m-1',
}) => CommunityImage(url: url, width: width, height: height);

const signedPoster = 'https://vz-abc.b-cdn.net/v-1/thumbnail.jpg?token=x';
const signedVideo = 'https://vz-abc.b-cdn.net/v-1/play_720p.mp4?token=x';

CommunityVideo testVideo({
  int width = 1080,
  int height = 1920,
  Duration duration = const Duration(seconds: 52),
  String? posterUrl = signedPoster,
  String? url = signedVideo,
  DateTime? urlExpiresAt,
}) => CommunityVideo(
  url: url,
  urlExpiresAt: urlExpiresAt,
  posterUrl: posterUrl,
  duration: duration,
  width: width,
  height: height,
);

CommunityPost testPost({
  int id = 1,
  CommunityAuthor author = huda,
  String text = istikhara,
  CommunityPostMedia media = const CommunityNoMedia(),
  int likeCount = 0,
  bool likedByMe = false,
  int commentCount = 0,
  DateTime? createdAt,
  bool canDelete = false,
  CommunityPostStatus status = CommunityPostStatus.published,
}) => CommunityPost(
  id: id,
  author: author,
  text: text,
  media: media,
  likeCount: likeCount,
  likedByMe: likedByMe,
  commentCount: commentCount,
  createdAt: createdAt,
  canDelete: canDelete,
  status: status,
);
