import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_strokes.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/design_system/widgets/qeran_card.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

part 'onboarding_community_card_parts.dart';

/// One guidance topic on the card: its glyph, its title and meta keys, and
/// the glyph of its kind (article, video, images).
typedef _Topic = ({IconData icon, String title, String meta, IconData kind});

/// The community slide's illustration: Community's header over three
/// guidance topics — what a member finds in the first tab. An illustration
/// only: the topics and names are examples, nothing here is tappable or read
/// from the server. Wine on the wine hero, so a gold-40 hairline edges it.
class OnboardingCommunityCard extends StatelessWidget {
  const OnboardingCommunityCard({super.key});

  static const List<_Topic> _topics = [
    (
      icon: Icons.person_search_outlined,
      title: LocaleKeys.onboarding_community_topic_choosing,
      meta: LocaleKeys.onboarding_community_topic_choosing_meta,
      kind: Icons.article_outlined,
    ),
    (
      icon: Icons.handshake_outlined,
      title: LocaleKeys.onboarding_community_topic_engagement,
      meta: LocaleKeys.onboarding_community_topic_engagement_meta,
      kind: Icons.smart_display_outlined,
    ),
    (
      icon: Icons.favorite_border_rounded,
      title: LocaleKeys.onboarding_community_topic_preparing,
      meta: LocaleKeys.onboarding_community_topic_preparing_meta,
      kind: Icons.photo_library_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return QeranCard(
      background: QeranColors.wine,
      borderColor: QeranColors.gold40,
      padding: const EdgeInsets.all(QeranSpacing.s16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Header(),
          QeranSpacing.vs12,
          for (final topic in _topics) ...[
            if (topic != _topics.first) QeranSpacing.vs8,
            _TopicRow(topic: topic),
          ],
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  static final _ring = BoxDecoration(
    shape: BoxShape.circle,
    border: Border.all(color: QeranColors.gold, width: QeranStrokes.regular),
  );

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Glyph(
          icon: Icons.groups_outlined,
          box: 44,
          iconSize: 24,
          decoration: _ring,
        ),
        QeranSpacing.hs12,
        Expanded(
          child: _TwoLines(
            title: LocaleKeys.onboarding_community_card_title.t(context),
            meta: LocaleKeys.onboarding_community_card_subtitle.t(context),
            header: true,
          ),
        ),
      ],
    );
  }
}

class _TopicRow extends StatelessWidget {
  final _Topic topic;

  const _TopicRow({required this.topic});

  static final _tile = BoxDecoration(
    color: QeranColors.wineLight,
    borderRadius: QeranRadii.controlR,
    border: Border.all(color: QeranColors.gold20, width: QeranStrokes.hairline),
  );

  static const _square = BoxDecoration(
    color: QeranColors.gold12,
    borderRadius: QeranRadii.xsR,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: QeranSpacing.s12,
        vertical: QeranSpacing.s8,
      ),
      decoration: _tile,
      child: Row(
        children: [
          _Glyph(icon: topic.icon, box: 36, iconSize: 20, decoration: _square),
          QeranSpacing.hs12,
          Expanded(
            child: _TwoLines(
              title: topic.title.t(context),
              meta: topic.meta.t(context),
            ),
          ),
          QeranSpacing.hs8,
          Icon(topic.kind, size: 20, color: QeranColors.gold40),
        ],
      ),
    );
  }
}
