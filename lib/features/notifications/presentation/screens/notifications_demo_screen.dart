import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:qeran/core/theme/app_color.dart';
import 'package:qeran/core/theme/app_text_style.dart';
import 'package:qeran/core/utils/app_dimens.dart';
import 'package:qeran/features/notifications/domain/entities/notification_entity.dart';
import 'package:qeran/features/notifications/presentation/data/mock_notifications.dart';
import 'package:qeran/features/notifications/presentation/widgets/notification_tile.dart';
import 'package:qeran/generated/locale_keys.g.dart';

/// Demo notifications screen — visual-only shell over mock data.
/// Replace mock list with a NotificationsCubit once the data layer lands.
class NotificationsDemoScreen extends StatefulWidget {
  const NotificationsDemoScreen({super.key});

  @override
  State<NotificationsDemoScreen> createState() =>
      _NotificationsDemoScreenState();
}

class _NotificationsDemoScreenState extends State<NotificationsDemoScreen> {
  late List<NotificationEntity> _items;

  @override
  void initState() {
    super.initState();
    _items = List.of(MockNotifications.items);
  }

  void _markAllAsRead() {
    setState(() {
      _items = _items
          .map(
            (n) => NotificationEntity(
              id: n.id,
              kind: n.kind,
              title: n.title,
              body: n.body,
              timeAgo: n.timeAgo,
              isRead: true,
            ),
          )
          .toList();
    });
  }

  void _markAsRead(int index) {
    final n = _items[index];
    if (n.isRead) return;
    setState(() {
      _items[index] = NotificationEntity(
        id: n.id,
        kind: n.kind,
        title: n.title,
        body: n.body,
        timeAgo: n.timeAgo,
        isRead: true,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasItems = _items.isNotEmpty;
    final hasUnread = _items.any((n) => !n.isRead);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          LocaleKeys.notifications_title.tr(),
          style: AppTextStyles.titleLarge.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          if (hasUnread)
            TextButton(
              onPressed: _markAllAsRead,
              child: Text(
                LocaleKeys.notifications_mark_all_read.tr(),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
      body: hasItems ? _buildList() : const _EmptyState(),
    );
  }

  Widget _buildList() {
    return ListView.separated(
      padding: const EdgeInsets.all(AppDimens.p16),
      itemCount: _items.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppDimens.p12),
      itemBuilder: (context, index) {
        return NotificationTile(
          notification: _items[index],
          onTap: () => _markAsRead(index),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.p24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.notifications_off_outlined,
              size: 64,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: AppDimens.p16),
            Text(
              LocaleKeys.notifications_empty_title.tr(),
              style: AppTextStyles.titleLarge.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppDimens.p8),
            Text(
              LocaleKeys.notifications_empty_subtitle.tr(),
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
