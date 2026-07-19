import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/widgets/qeran_card.dart';
import '../../../../../core/design_system/widgets/qeran_monogram.dart';
import '../../../../../core/design_system/widgets/qeran_section_header.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../../../settings/presentation/widgets/settings_logout_card.dart';
import '../../../../settings/presentation/widgets/settings_profile_hero.dart';
import '../../../../settings/presentation/widgets/settings_row.dart';
import '../../../shared/presentation/widgets/matchmaker_user_avatar.dart';
import '../../domain/entities/matchmaker_me.dart';
import 'referral_share_card.dart';

/// The loaded account screen body: wine hero (avatar + name + email) + the
/// "إدارة الحساب" rows + a standalone logout card. Purely presentational —
/// every action is a callback the screen owns. Composes the shared settings
/// kit (`SettingsProfileHero` / `SettingsRow` / `SettingsLogoutCard`), the same
/// atoms the user account screen uses. Bottom padding clears the bottom-nav.
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
    required this.onAffiliate,
    required this.onDeactivate,
    required this.onDeleteAccount,
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
  final VoidCallback onAffiliate;
  final VoidCallback onDeactivate;
  final VoidCallback onDeleteAccount;
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
        SettingsProfileHero(
          avatar: _HeroAvatar(url: me.image?.url, name: me.name),
          name: me.name,
          email: me.email,
          editLabel: LocaleKeys.matchmaker_account_edit_profile.t(context),
          onEdit: onEditName,
        ),
        // Referral/affiliate share card — shown only when the backend has issued
        // a code (never a fabricated placeholder for an absent one).
        if (me.referralCode != null && me.referralCode!.isNotEmpty) ...[
          QeranSpacing.vs16,
          ReferralShareCard(code: me.referralCode!),
        ],
        QeranSpacing.vs24,
        QeranSectionHeader(
          title: LocaleKeys.settings_account_management.t(context),
        ),
        QeranSpacing.vs12,
        QeranCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              SettingsRow(
                icon: Icons.badge_outlined,
                title: LocaleKeys.matchmaker_account_row_edit_name.t(context),
                onTap: onEditName,
              ),
              const SettingsRowDivider(),
              SettingsRow(
                icon: Icons.lock_outline_rounded,
                title:
                    LocaleKeys.matchmaker_account_change_password.t(context),
                onTap: onChangePassword,
              ),
              const SettingsRowDivider(),
              SettingsRow(
                icon: Icons.language_rounded,
                title: LocaleKeys.settings_language_row.t(context),
                subtitle: langSubtitle,
                onTap: onLanguage,
              ),
              const SettingsRowDivider(),
              SettingsRow(
                icon: Icons.notifications_outlined,
                title: LocaleKeys.settings_notifications_row.t(context),
                subtitle: LocaleKeys.settings_notifications_sub.t(context),
                onTap: onNotifications,
              ),
              const SettingsRowDivider(),
              SettingsRow(
                icon: Icons.chat_bubble_outline_rounded,
                title: LocaleKeys.settings_support_row.t(context),
                subtitle: LocaleKeys.settings_support_sub.t(context),
                onTap: onSupport,
              ),
              const SettingsRowDivider(),
              SettingsRow(
                icon: Icons.insights_outlined,
                title: LocaleKeys.matchmaker_affiliate_row_title.t(context),
                subtitle:
                    LocaleKeys.matchmaker_affiliate_row_subtitle.t(context),
                onTap: onAffiliate,
              ),
              const SettingsRowDivider(),
              SettingsRow(
                icon: Icons.description_outlined,
                title: LocaleKeys.settings_terms_row.t(context),
                subtitle: LocaleKeys.settings_terms_sub.t(context),
                onTap: onTerms,
              ),
              const SettingsRowDivider(),
              SettingsRow(
                icon: Icons.person_off_outlined,
                title: LocaleKeys.matchmaker_account_row_deactivate.t(context),
                onTap: onDeactivate,
                accent: SettingsRowAccent.danger,
              ),
              const SettingsRowDivider(),
              SettingsRow(
                icon: Icons.delete_forever_outlined,
                title: LocaleKeys.settings_delete_account.t(context),
                onTap: onDeleteAccount,
                accent: SettingsRowAccent.danger,
              ),
            ],
          ),
        ),
        QeranSpacing.vs24,
        SettingsLogoutCard(onTap: onLogout),
      ],
    );
  }
}

/// Hero avatar for the matchmaker: the JWT-headered photo when present (with a
/// wine+gold monogram fallback if it's missing or fails to load), inside a gold
/// ring — otherwise the [QeranMonogram] built from the name.
class _HeroAvatar extends StatelessWidget {
  const _HeroAvatar({required this.url, required this.name});

  final String? url;
  final String name;

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return QeranMonogram(name: name, size: 64);
    }
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: QeranColors.gold, width: 1.5),
      ),
      padding: const EdgeInsets.all(2),
      child: MatchmakerUserAvatar(url: url, size: 58, monogramName: name),
    );
  }
}
