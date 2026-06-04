import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/routes/navigation_manager.dart';
import 'package:qeran/features/questionnaire/presentation/screens/profile_edit_view.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import 'profile_self_view.dart';

/// The profile hub reached from Settings → عرض/تعديل الملف. Two top tabs:
/// عرض الملف الشخصي (the shared detailed view in self-mode) and تعديل الملف
/// (the category-tabbed edit form). The view tab reuses [ProfileSelfView];
/// the edit tab reuses the questionnaire's [ProfileEditView].
class ProfileHubScreen extends StatelessWidget {
  const ProfileHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: QeranColors.creamCanvas,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const _HubHeader(),
              const _TopTabBar(),
              Expanded(
                child: TabBarView(
                  children: const [ProfileSelfView(), ProfileEditView()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HubHeader extends StatelessWidget {
  const _HubHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(QeranSpacing.s8),
      child: Row(
        children: [
          const _BackButton(),
          Expanded(
            child: Text(
              LocaleKeys.profile_my_title.t(context),
              textAlign: TextAlign.center,
              style: QeranTypography.title.copyWith(
                color: QeranColors.wine,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          // Balances the back button so the title stays centered.
          const SizedBox(width: 40),
        ],
      ),
    );
  }
}

class _TopTabBar extends StatelessWidget {
  const _TopTabBar();

  @override
  Widget build(BuildContext context) {
    return TabBar(
      indicatorColor: QeranColors.wine,
      indicatorWeight: 2.5,
      dividerColor: QeranColors.wine12,
      labelColor: QeranColors.wine,
      unselectedLabelColor: QeranColors.inkMuted,
      labelStyle: QeranTypography.subtitle.copyWith(fontWeight: FontWeight.w700),
      unselectedLabelStyle: QeranTypography.subtitle,
      tabs: [
        Tab(text: LocaleKeys.profile_tab_view.t(context)),
        Tab(text: LocaleKeys.profile_tab_edit.t(context)),
      ],
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: QeranColors.paper,
      shape: const CircleBorder(side: BorderSide(color: QeranColors.wine08)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => NavigationManager.pop(context),
        child: const SizedBox(
          width: 40,
          height: 40,
          // arrow_back_ios_new auto-mirrors under the ambient Directionality.
          child: Icon(
            Icons.arrow_back_ios_new,
            color: QeranColors.wine,
            size: 20,
          ),
        ),
      ),
    );
  }
}
