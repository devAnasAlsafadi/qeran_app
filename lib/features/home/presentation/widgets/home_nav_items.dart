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
/// Discovery carries none. `exploreUnread` is documented as permanently zero,
/// and a tab that can never light must not wear a badge implying it might.
List<QeranNavItem> buildHomeNavItems(
  BuildContext context,
  BadgeCounts badges,
) => [
  QeranNavItem(
    outlineIcon: Icons.diamond_outlined,
    filledIcon: Icons.diamond_rounded,
    label: LocaleKeys.home_nav_marriage.t(context),
  ),
  QeranNavItem(
    outlineIcon: Icons.favorite_border_rounded,
    filledIcon: Icons.favorite_rounded,
    label: LocaleKeys.home_nav_likes.t(context),
    badgeCount: badges.likes,
    badgeIsDot: true,
  ),
  QeranNavItem(
    outlineIcon: Icons.chat_bubble_outline_rounded,
    filledIcon: Icons.chat_bubble_rounded,
    label: LocaleKeys.home_nav_messages.t(context),
    badgeCount: badges.chat,
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
