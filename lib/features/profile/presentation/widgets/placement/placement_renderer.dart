import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/widgets/qeran_card.dart';

import '../../../domain/entities/placement.dart';
import '../../../domain/entities/placement_code.dart';
import 'about_me_section.dart';
import 'about_partner_section.dart';
import 'inside_chips_section.dart';
import 'interests_section.dart';
import 'profile_section_header.dart';
import 'qa_default_section.dart';

/// Top-level section dispatcher. Bucket-sorts placements by [PlacementCode]
/// then emits widgets in a deterministic order:
///   aboutMe → insideChips → aboutPartner → defaultGroup[*] → interests[*]
/// `aboveImage` is drawn over the image, so it is skipped here.
class PlacementRenderer extends StatelessWidget {
  final List<Placement> placements;

  /// When true (default), divider hairlines separate sections in the
  /// flat (non-card) layout.
  final bool withDividers;

  /// When true, each section renders inside its own [QeranCard] (the
  /// full-profile-details layout). Default `false` keeps the flat
  /// divider-separated list used by my-profile / matchmaker bodies.
  final bool asCards;

  /// When false (card layout only), the aboutMe + insideCard sections are
  /// skipped here — the full-profile body draws them in its main card.
  final bool includeNarrative;

  const PlacementRenderer({
    super.key,
    required this.placements,
    this.withDividers = true,
    this.asCards = false,
    this.includeNarrative = true,
  });

  @override
  Widget build(BuildContext context) {
    if (asCards) return _buildCardColumn();
    final sections = _buildSections();
    if (sections.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < sections.length; i++) ...[
          sections[i],
          if (withDividers && i != sections.length - 1)
            const ProfileSectionDivider(),
        ],
      ],
    );
  }

  Widget _buildCardColumn() {
    final cards = _buildCards();
    if (cards.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          cards[i],
          if (i != cards.length - 1) QeranSpacing.vs16,
        ],
      ],
    );
  }

  _Buckets _bucket() {
    final b = _Buckets();
    for (final p in placements) {
      switch (p.code) {
        case PlacementCode.aboutMe:
          b.aboutMe ??= p;
        case PlacementCode.insideCard:
          b.insideCard ??= p;
        case PlacementCode.aboutPartner:
          b.aboutPartner ??= p;
        case PlacementCode.interests:
          b.interests.add(p);
        case PlacementCode.defaultGroup:
          b.defaults.add(p);
        case PlacementCode.aboveImage:
          break;
      }
    }
    return b;
  }

  List<Widget> _buildSections() {
    final b = _bucket();
    final out = <Widget>[];
    if (b.aboutMe != null) out.add(AboutMeSection(placement: b.aboutMe!));
    if (b.insideCard != null && b.insideCard!.items.isNotEmpty) {
      out.add(InsideChipsSection(placement: b.insideCard!));
    }
    if (b.aboutPartner != null) {
      out.add(AboutPartnerSection(placement: b.aboutPartner!));
    }
    for (final d in b.defaults) {
      out.add(QaDefaultSection(placement: d));
    }
    for (final i in b.interests) {
      out.add(InterestsSection(placement: i));
    }
    return out;
  }

  List<Widget> _buildCards() {
    final b = _bucket();
    final hasInside = b.insideCard != null && b.insideCard!.items.isNotEmpty;
    final cards = <Widget>[];
    if (includeNarrative) {
      if (b.aboutMe != null) {
        cards.add(
          QeranCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AboutMeSection(placement: b.aboutMe!),
                if (hasInside) ...[
                  QeranSpacing.vs16,
                  InsideChipsSection(placement: b.insideCard!),
                ],
              ],
            ),
          ),
        );
      } else if (hasInside) {
        cards.add(QeranCard(child: InsideChipsSection(placement: b.insideCard!)));
      }
    }
    if (b.aboutPartner != null) {
      cards.add(QeranCard(child: AboutPartnerSection(placement: b.aboutPartner!)));
    }
    for (final d in b.defaults) {
      cards.add(QeranCard(child: QaDefaultSection(placement: d)));
    }
    for (final i in b.interests) {
      cards.add(QeranCard(child: InterestsSection(placement: i)));
    }
    return cards;
  }
}

class _Buckets {
  Placement? aboutMe;
  Placement? insideCard;
  Placement? aboutPartner;
  final List<Placement> interests = [];
  final List<Placement> defaults = [];
}
