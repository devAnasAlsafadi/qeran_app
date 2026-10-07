import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/datasources/shared_pref_service.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/matchmaker/notifications/domain/entities/matchmaker_notification.dart';
import 'package:qeran/features/matchmaker/notifications/domain/entities/matchmaker_notifications_page.dart';
import 'package:qeran/features/matchmaker/notifications/domain/repositories/matchmaker_notifications_repository.dart';
import 'package:qeran/features/matchmaker/notifications/domain/usecases/get_notifications_usecase.dart';
import 'package:qeran/features/matchmaker/notifications/presentation/blocs/matchmaker_notification_read_cubit.dart';
import 'package:qeran/features/matchmaker/notifications/presentation/blocs/matchmaker_notifications_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A notification on post 1 as the server sends it to her (contract §7.2).
MatchmakerNotification _community(
  int id,
  String action, {
  required (String, String) title,
  required (String, String) body,
  Map<String, String> ids = const {'commentId': '10'},
}) => MatchmakerNotification(
  id: id,
  titleAr: title.$1,
  titleEn: title.$2,
  bodyAr: body.$1,
  bodyEn: body.$2,
  type: MatchmakerNotificationType.community,
  data: {
    'type': 'Community',
    'screen': 'community_post',
    'action': action,
    'audience': 'matchmaker',
    'postId': '1',
    ...ids,
  },
  createdAt: null,
);

/// A new comment (10) on her post.
final herComment = _community(
  3,
  'community_comment',
  title: ('تعليق جديد على منشورك', 'New comment on your post'),
  body: ('ديما: جزاكِ الله خيراً', 'Dima: Thank you'),
);

/// A reply (100) to her comment (10) — D31.
final herReply = _community(
  2,
  'community_reply',
  title: ('ردّ جديد على تعليقك', 'New reply to your comment'),
  body: ('ديما: وإياكِ', 'Dima: And you'),
  ids: const {'commentId': '10', 'replyId': '100'},
);

/// A report on reply 100, under comment 10.
final herReport = _community(
  1,
  'community_report',
  title: ('بلاغ على منشورك', 'Report on your post'),
  body: (
    'تم الإبلاغ عن رد ديما: «إساءة».',
    'Dima’s reply was reported: “Abuse”.',
  ),
  ids: const {'commentId': '10', 'replyId': '100', 'flagId': '7'},
);

class _Inbox implements MatchmakerNotificationsRepository {
  _Inbox(this.items);

  final List<MatchmakerNotification> items;

  @override
  Future<Either<Failure, MatchmakerNotificationsPage>> getNotifications({
    required int page,
    required int pageSize,
  }) async => Right(
    MatchmakerNotificationsPage(
      items: page == 1 ? items : const [],
      hasMore: false,
    ),
  );
}

/// Her inbox's cubits over [items]; the caller registers [BadgesCubit].
Future<void> registerHerInbox(List<MatchmakerNotification> items) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = SharedPrefService(await SharedPreferences.getInstance());
  final usecase = GetNotificationsUseCase(_Inbox(items));
  sl
    ..registerFactory(
      () => MatchmakerNotificationsCubit(getNotifications: usecase),
    )
    ..registerFactory(() => MatchmakerNotificationReadCubit(prefs: prefs));
  addTearDown(() async => sl.reset());
}
