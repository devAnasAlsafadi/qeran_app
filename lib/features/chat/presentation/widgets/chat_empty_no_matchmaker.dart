import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/effects/ring_motif.dart';
import 'package:qeran/core/design_system/motion/soft_scale_in.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_motion.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

/// Calm waiting surface shown when `/my-matchmaker` reports `status:0`
/// (no matchmaker assigned yet). The visual language signals
/// "someone is taking care of your journey", not "no data."
class ChatEmptyNoMatchmaker extends StatelessWidget {
  final Future<void> Function() onRefresh;
  const ChatEmptyNoMatchmaker({super.key, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: QeranColors.wine,
      onRefresh: onRefresh,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: ColoredBox(
                color: QeranColors.creamCanvas,
                child: Padding(
                  padding: const EdgeInsets.all(QeranSpacing.s32),
                  child: Center(
                    child: SoftScaleIn(
                      duration: QeranMotion.gentle,
                      beginScale: 0.96,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 320),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const _WaitingMark(),
                            QeranSpacing.vs24,
                            Text(
                              LocaleKeys.chat_entry_no_matchmaker_title
                                  .t(context),
                              textAlign: TextAlign.center,
                              style: QeranTypography.headline,
                            ),
                            QeranSpacing.vs12,
                            Text(
                              LocaleKeys.chat_entry_no_matchmaker_subtitle
                                  .t(context),
                              textAlign: TextAlign.center,
                              style: QeranTypography.body,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Brand mark for the waiting state — two concentric gold ring motifs
/// behind a gold-ringed disc holding the handshake icon. Reads as
/// "warmth + care + premium attention", not as a placeholder badge.
class _WaitingMark extends StatelessWidget {
  const _WaitingMark();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const RingMotif(
            color: QeranColors.gold,
            opacity: 0.10,
            size: 160,
            ringCount: 2,
            spacing: 14,
          ),
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: QeranColors.gold.withValues(alpha: 0.18),
              border: Border.all(color: QeranColors.gold, width: 1.4),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.handshake_rounded,
              size: 40,
              color: QeranColors.wine,
            ),
          ),
        ],
      ),
    );
  }
}
