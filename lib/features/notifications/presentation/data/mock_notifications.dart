import 'package:qeran/features/notifications/domain/entities/notification_entity.dart';

/// TEMPORARY — visual-only fixtures used to preview the Notifications
/// screen before the data layer is wired. Replace once the notifications
/// repository + cubit are in place.
class MockNotifications {
  MockNotifications._();

  static const List<NotificationEntity> items = [
    NotificationEntity(
      id: 'n-1',
      kind: NotificationKind.match,
      title: 'تطابق جديد',
      body: 'لديك توافق جديد مع أحمد صالح، ابدأ المحادثة الآن.',
      timeAgo: 'قبل دقيقتين',
    ),
    NotificationEntity(
      id: 'n-2',
      kind: NotificationKind.like,
      title: 'إعجاب جديد',
      body: 'شخص ما أبدى إعجابه بملفك الشخصي.',
      timeAgo: 'قبل 10 دقائق',
    ),
    NotificationEntity(
      id: 'n-3',
      kind: NotificationKind.message,
      title: 'رسالة جديدة',
      body: 'وصلتك رسالة من يوسف عمر.',
      timeAgo: 'قبل ساعة',
      isRead: true,
    ),
    NotificationEntity(
      id: 'n-4',
      kind: NotificationKind.system,
      title: 'اكتمل ملفك الشخصي',
      body: 'لقد أكملت ملفك الشخصي بنجاح، أصبحت ظاهرًا للمستخدمين.',
      timeAgo: 'أمس',
      isRead: true,
    ),
  ];
}
