import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/design_system/theme/qeran_system_bars.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/widgets/qeran_app_bar.dart';
import 'package:qeran/core/design_system/widgets/qeran_bell_button.dart';
import 'package:qeran/features/badges/domain/entities/badge_counts.dart';
import 'package:qeran/features/chat/presentation/blocs/my_matchmaker_cubit.dart';
import 'package:qeran/features/chat/presentation/blocs/my_matchmaker_state.dart';

import '../home_back_trail.dart';
import '../home_shell_scope.dart';
import 'shell_matchmaker_block.dart';

/// The user shell's top bar, above every tab: pinned — the nav hides on
/// scroll, this never does — on paper that runs up under the status bar.
///
/// Start to end: a back chevron, only while a notifications trail is live;
/// the matchmaker block, one tap target that opens the chat; the bell, which
/// opens the inbox. The bar owns the status-bar inset, so the tabs below it
/// start at its bottom edge.
class ShellTopBar extends StatelessWidget {
  const ShellTopBar({
    super.key,
    required this.badges,
    required this.onOpenChat,
    required this.onOpenInbox,
  });

  final BadgeCounts badges;
  final VoidCallback onOpenChat;
  final VoidCallback onOpenInbox;

  static const double height = 64;
  static const double landscapeHeight = 56;

  @override
  Widget build(BuildContext context) {
    final shell = HomeShellScope.maybeOf(context);
    final showBack = shell?.backTrail == HomeBackTrail.notifications;
    final size = MediaQuery.sizeOf(context);
    final isLandscape = size.width > size.height;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: QeranSystemBars.darkIcons,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: QeranColors.paper,
          border: Border(bottom: BorderSide(color: QeranColors.divider)),
        ),
        // The block's and the bell's ripples paint on the nearest Material;
        // without this one it is the Scaffold's, under the paper, unseen.
        child: Material(
          type: MaterialType.transparency,
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              height: isLandscape ? landscapeHeight : height,
              child: Padding(
                padding: EdgeInsetsDirectional.only(
                  start: showBack ? QeranSpacing.s4 : QeranSpacing.s12,
                  end: QeranSpacing.s6,
                ),
                child: Row(
                  children: [
                    if (showBack) ...[
                      QeranBackButton(onTap: shell!.followBackTrail),
                      const SizedBox(width: QeranSpacing.s2),
                    ],
                    Expanded(
                      child: BlocBuilder<MyMatchmakerCubit, MyMatchmakerState>(
                        builder: (context, matchmaker) => ShellMatchmakerBlock(
                          matchmaker: matchmaker,
                          chatUnread: badges.chat,
                          onTap: onOpenChat,
                        ),
                      ),
                    ),
                    const SizedBox(width: QeranSpacing.s2),
                    QeranBellButton(
                      count: badges.notifications,
                      onTap: onOpenInbox,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
