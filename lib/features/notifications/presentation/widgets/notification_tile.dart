import 'package:flutter/material.dart';
import 'package:qeran/core/theme/app_color.dart';
import 'package:qeran/core/theme/app_text_style.dart';
import 'package:qeran/core/utils/app_dimens.dart';
import 'package:qeran/features/notifications/domain/entities/notification_entity.dart';

class NotificationTile extends StatelessWidget {
  final NotificationEntity notification;
  final VoidCallback? onTap;

  const NotificationTile({
    super.key,
    required this.notification,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppDimens.borderRadius12,
      child: Container(
        padding: const EdgeInsets.all(AppDimens.p12),
        decoration: BoxDecoration(
          color: notification.isRead
              ? AppColors.background
              : AppColors.surface,
          borderRadius: AppDimens.borderRadius12,
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _LeadingIcon(kind: notification.kind),
            const SizedBox(width: AppDimens.p12),
            Expanded(child: _Content(notification: notification)),
            if (!notification.isRead) ...[
              const SizedBox(width: AppDimens.p8),
              const _UnreadDot(),
            ],
          ],
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  final NotificationEntity notification;
  const _Content({required this.notification});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          notification.title,
          style: AppTextStyles.titleLarge.copyWith(
            fontSize: 15,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppDimens.p4),
        Text(
          notification.body,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppDimens.p8),
        Text(
          notification.timeAgo,
          style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
        ),
      ],
    );
  }
}

class _LeadingIcon extends StatelessWidget {
  final NotificationKind kind;
  const _LeadingIcon({required this.kind});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        shape: BoxShape.circle,
      ),
      child: Icon(_iconFor(kind), color: AppColors.primary, size: 20),
    );
  }

  IconData _iconFor(NotificationKind kind) => switch (kind) {
    NotificationKind.match => Icons.favorite_outline,
    NotificationKind.like => Icons.thumb_up_alt_outlined,
    NotificationKind.message => Icons.chat_bubble_outline,
    NotificationKind.system => Icons.info_outline,
  };
}

class _UnreadDot extends StatelessWidget {
  const _UnreadDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: AppColors.error,
        shape: BoxShape.circle,
      ),
    );
  }
}
