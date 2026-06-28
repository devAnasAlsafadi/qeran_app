import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../../core/design_system/widgets/qeran_card.dart';
import '../../../../../core/design_system/widgets/qeran_section_header.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../domain/entities/matchmaker_me.dart';
import 'matchmaker_account_header_card.dart';
import 'matchmaker_settings_row.dart';

/// The loaded account screen body: header card + "إدارة الحساب" rows + a
/// standalone logout card. Purely presentational — every action is a callback
/// the screen owns. The bottom padding clears the curved bottom-nav.
class MatchmakerAccountBody extends StatelessWidget {
  const MatchmakerAccountBody({
    super.key,
    required this.me,
    required this.onEditName,
    required this.onChangePassword,
    required this.onLanguage,
    required this.onNotifications,
    required this.onSupport,
    required this.onTerms,
    required this.onDeactivate,
    required this.onLogout,
    required this.bottomReserve,
  });

  final MatchmakerMe me;
  final VoidCallback onEditName;
  final VoidCallback onChangePassword;
  final VoidCallback onLanguage;
  final VoidCallback onNotifications;
  final VoidCallback onSupport;
  final VoidCallback onTerms;
  final VoidCallback onDeactivate;
  final VoidCallback onLogout;
  final double bottomReserve;

  @override
  Widget build(BuildContext context) {
    final langSubtitle = context.locale.languageCode == 'ar'
        ? LocaleKeys.settings_lang_arabic.t(context)
        : LocaleKeys.settings_lang_english.t(context);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: EdgeInsets.fromLTRB(
        QeranSpacing.s16,
        QeranSpacing.s16,
        QeranSpacing.s16,
        QeranSpacing.s24 + bottomReserve,
      ),
      children: [
        MatchmakerAccountHeaderCard(me: me, onEdit: onEditName),
        QeranSpacing.vs24,
        QeranSectionHeader(
          title: LocaleKeys.settings_account_management.t(context),
        ),
        QeranSpacing.vs12,
        QeranCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              MatchmakerSettingsRow(
                icon: Icons.badge_outlined,
                title: LocaleKeys.matchmaker_account_row_edit_name.t(context),
                onTap: onEditName,
              ),
              const MatchmakerSettingsRowDivider(),
              MatchmakerSettingsRow(
                icon: Icons.lock_outline_rounded,
                title:
                    LocaleKeys.matchmaker_account_change_password.t(context),
                onTap: onChangePassword,
              ),
              const MatchmakerSettingsRowDivider(),
              MatchmakerSettingsRow(
                icon: Icons.language_rounded,
                title: LocaleKeys.settings_language_row.t(context),
                subtitle: langSubtitle,
                onTap: onLanguage,
              ),
              const MatchmakerSettingsRowDivider(),
              MatchmakerSettingsRow(
                icon: Icons.notifications_outlined,
                title: LocaleKeys.settings_notifications_row.t(context),
                subtitle: LocaleKeys.settings_notifications_sub.t(context),
                onTap: onNotifications,
              ),
              const MatchmakerSettingsRowDivider(),
              MatchmakerSettingsRow(
                icon: Icons.chat_bubble_outline_rounded,
                title: LocaleKeys.settings_support_row.t(context),
                subtitle: LocaleKeys.settings_support_sub.t(context),
                onTap: onSupport,
              ),
              const MatchmakerSettingsRowDivider(),
              MatchmakerSettingsRow(
                icon: Icons.description_outlined,
                title: LocaleKeys.settings_terms_row.t(context),
                subtitle: LocaleKeys.settings_terms_sub.t(context),
                onTap: onTerms,
              ),
              const MatchmakerSettingsRowDivider(),
              MatchmakerSettingsRow(
                icon: Icons.person_off_outlined,
                title: LocaleKeys.matchmaker_account_row_deactivate.t(context),
                onTap: onDeactivate,
                destructive: true,
              ),
            ],
          ),
        ),
        QeranSpacing.vs24,
        _LogoutCard(onTap: onLogout),
      ],
    );
  }
}

class _LogoutCard extends StatelessWidget {
  const _LogoutCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return QeranCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: QeranColors.danger.withValues(alpha: 0.12),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.logout_rounded,
              color: QeranColors.danger,
              size: 20,
            ),
          ),
          QeranSpacing.hs12,
          Expanded(
            child: Text(
              LocaleKeys.common_logout.t(context),
              style: QeranTypography.body.copyWith(color: QeranColors.danger),
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: QeranColors.wine,
            size: 22,
          ),
        ],
      ),
    );
  }
}
