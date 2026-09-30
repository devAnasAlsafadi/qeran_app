import 'package:flutter/widgets.dart';
import 'package:qeran/core/widgets/connectivity_banner_host.dart';
import 'package:qeran/features/badges/domain/entities/badge_counts.dart';

import 'shell_top_bar.dart';

/// The user shell above the nav: the top bar, the tabs below it, and between
/// them the place the offline banner comes out from under the bar, rather
/// than covering it.
///
/// The bar owns the status-bar inset, so the tabs start at its bottom edge.
class HomeShellBody extends StatelessWidget {
  const HomeShellBody({
    super.key,
    required this.badges,
    required this.onOpenChat,
    required this.onOpenInbox,
    required this.tabs,
  });

  final BadgeCounts badges;
  final VoidCallback onOpenChat;
  final VoidCallback onOpenInbox;
  final Widget tabs;

  @override
  Widget build(BuildContext context) {
    return AttachedConnectivityBanner(
      child: Column(
        children: [
          ShellTopBar(
            badges: badges,
            onOpenChat: onOpenChat,
            onOpenInbox: onOpenInbox,
          ),
          const ConnectivityBannerSlot(),
          Expanded(
            child: MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: tabs,
            ),
          ),
        ],
      ),
    );
  }
}
