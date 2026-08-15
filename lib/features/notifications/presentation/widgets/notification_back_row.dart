import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/widgets/qeran_app_bar.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';

/// The "back to the inbox" control for a bottom-nav TAB reached from a
/// notification.
///
/// The matchmaker tabs each own a [MatchmakerAppBar] and take a leading through
/// it; the user-app tabs have no app bar at all — Likes carries a
/// `QeranSectionHeader`, Profile opens straight onto its hero card — so there
/// is no leading slot to fill. This row is that slot: one widget for all three
/// user tabs, so the affordance lands in the same place at the same size
/// wherever it appears, instead of being fitted into three different headers.
///
/// Start-aligned, so it mirrors with the locale like every other back control.
class NotificationBackRow extends StatelessWidget {
  const NotificationBackRow({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: QeranSpacing.s4),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: QeranBackButton(onTap: onBack),
      ),
    );
  }
}
