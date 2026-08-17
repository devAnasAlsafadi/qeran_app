import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_radii.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../../core/design_system/widgets/qeran_card.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../../shared/presentation/widgets/matchmaker_user_avatar.dart';
import '../../domain/entities/matchmaker_conversation.dart';

/// One conversation row: unblurred avatar + name over the preview (or a
/// "shared profile" label), with a trailing meta-column carrying the readable
/// relative time on top and a distinct gold unread pill below. Tappable.
class MatchmakerConversationCard extends StatelessWidget {
  const MatchmakerConversationCard({
    super.key,
    required this.conversation,
    this.onTap,
  });

  final MatchmakerConversation conversation;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final time = _time(context);
    final unread = conversation.unreadCount;
    return QeranCard(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: QeranSpacing.s12),
      padding: const EdgeInsets.all(QeranSpacing.s12),
      child: Row(
        children: [
          MatchmakerUserAvatar(
            url: conversation.profileImageUrl,
            size: 52,
            monogramName: conversation.fullName,
          ),
          QeranSpacing.hs12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  conversation.fullName,
                  style: QeranTypography.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                QeranSpacing.vs4,
                _preview(context),
              ],
            ),
          ),
          if (time != null || unread > 0) ...[
            QeranSpacing.hs8,
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (time != null)
                  Text(
                    time,
                    style: QeranTypography.caption
                        .copyWith(color: QeranColors.inkMuted),
                  ),
                if (unread > 0) ...[
                  const SizedBox(height: QeranSpacing.s6),
                  _UnreadPill(count: unread),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Readable, localized relative time (numerals LTR), falling back to a
  /// short date once past a week. Never the old cramped "{n}letter" form.
  String? _time(BuildContext context) {
    final at = conversation.lastMessageAt;
    if (at == null) return null;
    final local = at.toLocal();
    final diff = DateTime.now().difference(local);
    if (diff.inMinutes < 1) {
      return LocaleKeys.matchmaker_conversations_time_now.t(context);
    }
    if (diff.inMinutes < 60) {
      return context.tr(
        LocaleKeys.matchmaker_conversations_time_minutes_ago,
        namedArgs: {'count': '${diff.inMinutes}'},
      );
    }
    if (diff.inHours < 24) {
      return context.tr(
        LocaleKeys.matchmaker_conversations_time_hours_ago,
        namedArgs: {'count': '${diff.inHours}'},
      );
    }
    if (diff.inDays < 2) {
      return LocaleKeys.matchmaker_conversations_time_yesterday.t(context);
    }
    if (diff.inDays < 7) {
      return context.tr(
        LocaleKeys.matchmaker_conversations_time_days_ago,
        namedArgs: {'count': '${diff.inDays}'},
      );
    }
    try {
      return DateFormat.MMMd(context.locale.toString()).format(local);
    } catch (_) {
      final m = local.month.toString().padLeft(2, '0');
      final d = local.day.toString().padLeft(2, '0');
      return '${local.year}/$m/$d';
    }
  }

  Widget _preview(BuildContext context) {
    if (conversation.isSharedProfilePreview) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.account_circle_outlined,
            size: 14,
            color: QeranColors.wine,
          ),
          QeranSpacing.hs4,
          Flexible(
            child: Text(
              LocaleKeys.matchmaker_conversations_shared_profile.t(context),
              style: QeranTypography.caption.copyWith(color: QeranColors.wine),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }
    // Resolved HERE so `context.locale` registers the dependency: switching
    // language repaints the row, same as the thread's bubbles. A REST-loaded
    // row carries no localization tuple and falls through to the
    // server-rendered preview.
    final isArabic = context.locale.languageCode == 'ar';
    return Text(
      conversation.previewText(isArabic: isArabic),
      style: QeranTypography.caption.copyWith(color: QeranColors.inkMuted),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// Unread count as a distinct gold pill with a wine numeral (LTR, capped at
/// "99+"). Scoped to the inbox row — the shared circular count badge stays as
/// it is for the segmented tabs.
class _UnreadPill extends StatelessWidget {
  const _UnreadPill({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 20),
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: QeranSpacing.s6),
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: QeranColors.gold,
        borderRadius: QeranRadii.pill,
      ),
      child: Text(
        // Latin digits are inherently LTR; no textDirection override needed
        // (and easy_localization shadows ui.TextDirection here).
        count > 99 ? '99+' : '$count',
        style: QeranTypography.caption.copyWith(
          color: QeranColors.wine,
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
      ),
    );
  }
}
