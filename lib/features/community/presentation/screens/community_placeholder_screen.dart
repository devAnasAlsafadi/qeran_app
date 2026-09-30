import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/design_system/widgets/qeran_bottom_nav.dart';
import 'package:qeran/core/design_system/widgets/qeran_dashed_ring.dart';
import 'package:qeran/core/design_system/widgets/qeran_section_header.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

/// The Community tab until Phase 2 builds the feed: the tab's title and a
/// dashed frame where the feed will go.
///
/// It never ships — nothing is published before Phases 1–4 are done — so its
/// one line of copy is a temporary key that Phase 2 deletes with this file.
class CommunityPlaceholderScreen extends StatelessWidget {
  const CommunityPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              QeranSpacing.s20,
              QeranSpacing.s16,
              QeranSpacing.s20,
              QeranSpacing.s8,
            ),
            child: QeranSectionHeader(
              title: LocaleKeys.home_nav_community.t(context),
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                QeranSpacing.s16,
                QeranSpacing.s8,
                QeranSpacing.s16,
                QeranBottomNav.contentClearance(context),
              ),
              child: const _FeedFrame(),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedFrame extends StatelessWidget {
  const _FeedFrame();

  @override
  Widget build(BuildContext context) {
    return QeranDashedRing(
      color: QeranColors.wine20,
      borderRadius: QeranRadii.cardR,
      child: Padding(
        padding: const EdgeInsets.all(QeranSpacing.s16),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.dynamic_feed_rounded,
                size: 32,
                color: QeranColors.inkFaint,
              ),
              QeranSpacing.vs8,
              Text(
                LocaleKeys.community_placeholder_body.t(context),
                textAlign: TextAlign.center,
                style: QeranTypography.bodySm.copyWith(
                  color: QeranColors.inkMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
