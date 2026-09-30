import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/widgets/qeran_bottom_nav.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/features/badges/domain/entities/badge_counts.dart';
import 'package:qeran/generated/locale_keys.g.dart';

/// The user shell's bottom-nav items, in tab order.
///
/// Dots, not numbers: a tab stands for one thing, so "there is something here"
/// is the whole message. The real count is passed regardless — it decides
/// whether the dot shows at all, and it leaves the door open to numbers without
/// a design-system change.
///
/// Community and Suggestions carry none. Community has no badge key, and
/// `exploreUnread` is documented as permanently zero: a tab that can never
/// light must not wear a badge implying it might. Chat is not a tab; its
/// unread count belongs to the shell's top bar.
List<QeranNavItem> buildHomeNavItems(
  BuildContext context,
  BadgeCounts badges,
) => [
  QeranNavItem(
    outlineIcon: Icons.groups_outlined,
    filledIcon: Icons.groups_rounded,
    label: LocaleKeys.home_nav_community.t(context),
  ),
  QeranNavItem(
    outlineIcon: Icons.diamond_outlined,
    filledIcon: Icons.diamond_rounded,
    label: LocaleKeys.home_nav_marriage.t(context),
  ),
  QeranNavItem(
    outlineIcon: Icons.volunteer_activism_outlined,
    filledIcon: Icons.volunteer_activism_rounded,
    label: LocaleKeys.home_nav_likes.t(context),
    badgeCount: badges.likes,
    badgeIsDot: true,
  ),
  QeranNavItem(
    outlineIcon: Icons.person_outline_rounded,
    filledIcon: Icons.person_rounded,
    label: LocaleKeys.home_nav_profile.t(context),
    badgeCount: badges.account,
    badgeIsDot: true,
  ),
];
