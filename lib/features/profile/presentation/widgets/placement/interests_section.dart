import 'package:flutter/material.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/theme/app_color.dart';
import 'package:qeran/core/theme/app_text_style.dart';
import 'package:qeran/core/utils/app_dimens.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../../domain/entities/placement.dart';
import '../../../domain/entities/placement_value.dart';
import 'profile_section_header.dart';

/// Flat interests section — burgundy header + wrap of pill chips.
/// Server display strings already include the emoji marker
/// (e.g. "🧭 محبة للسفر"), so each chip just renders the string verbatim.
class InterestsSection extends StatelessWidget {
  final Placement placement;
  const InterestsSection({super.key, required this.placement});

  @override
  Widget build(BuildContext context) {
    final chips = _collectChips();
    if (chips.isEmpty) return const SizedBox.shrink();
    final title = placement.name.trim().isNotEmpty
        ? placement.name
        : LocaleKeys.profile_details_interests_title.t(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ProfileSectionHeader(
          title: title,
          icon: Icons.auto_awesome_outlined,
        ),
        const SizedBox(height: AppDimens.p12),
        Wrap(
          spacing: AppDimens.p8,
          runSpacing: AppDimens.p8,
          children: chips.map(_InterestPill.new).toList(growable: false),
        ),
      ],
    );
  }

  List<String> _collectChips() {
    final out = <String>[];
    for (final item in placement.items) {
      switch (item.display) {
        case PlacementSingle(value: final v):
          final t = v.trim();
          if (t.isNotEmpty) out.add(t);
        case PlacementMulti(values: final vs):
          for (final v in vs) {
            final t = v.trim();
            if (t.isNotEmpty) out.add(t);
          }
      }
    }
    return out;
  }
}

class _InterestPill extends StatelessWidget {
  final String label;
  const _InterestPill(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.p12,
        vertical: AppDimens.p8,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.18),
        ),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
