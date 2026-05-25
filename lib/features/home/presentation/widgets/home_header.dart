import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/theme/app_color.dart';
import 'package:qeran/core/theme/app_text_style.dart';
import 'package:qeran/core/utils/app_dimens.dart';
import 'package:qeran/generated/locale_keys.g.dart';

/// Top-of-screen header: notification bell on one side, greeting text +
/// circular avatar on the other. Direction-aware via Row's natural RTL.
class HomeHeader extends StatelessWidget {
  final String userName;
  final String? userPhotoUrl;
  final bool hasUnread;
  final VoidCallback? onNotificationsTap;
  final VoidCallback? onAvatarTap;

  const HomeHeader({
    super.key,
    required this.userName,
    this.userPhotoUrl,
    this.hasUnread = false,
    this.onNotificationsTap,
    this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _NotificationBell(
          hasUnread: hasUnread,
          onTap: onNotificationsTap,
        ),
        const Spacer(),
        Flexible(
          flex: 5,
          child: _Greeting(userName: userName),
        ),
        const SizedBox(width: AppDimens.p12),
        _Avatar(url: userPhotoUrl, onTap: onAvatarTap),
      ],
    );
  }
}

class _Greeting extends StatelessWidget {
  final String userName;
  const _Greeting({required this.userName});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          LocaleKeys.home_greeting.tr(namedArgs: {'name': userName}),
          style: AppTextStyles.titleLarge.copyWith(
            color: AppColors.textPrimary,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppDimens.p4),
        Text(
          LocaleKeys.home_greeting_subtitle.t(context),
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.end,
        ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? url;
  final VoidCallback? onTap;
  const _Avatar({required this.url, this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasUrl = url != null && url!.isNotEmpty;
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: CircleAvatar(
        radius: 24,
        backgroundColor: AppColors.greyLight,
        backgroundImage: hasUrl ? NetworkImage(url!) : null,
        child: hasUrl
            ? null
            : const Icon(Icons.person, color: AppColors.textMuted),
      ),
    );
  }
}

class _NotificationBell extends StatelessWidget {
  final bool hasUnread;
  final VoidCallback? onTap;
  const _NotificationBell({required this.hasUnread, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        padding: const EdgeInsets.all(AppDimens.p8 + 2),
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(
              Icons.notifications_outlined,
              color: AppColors.primary,
              size: 22,
            ),
            if (hasUnread)
              Positioned(
                top: -1,
                right: -1,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
