import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/widgets/qeran_text_field.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../../shared/presentation/widgets/matchmaker_segmented_tabs.dart';

/// The explore header controls: a search field + filter affordance on one row,
/// with the gender segmented control beneath. All callback-driven — the parent
/// owns the debounce, the gender mapping, and the filter sheet. A gold dot on
/// the filter icon marks active question filters.
class MatchmakerExploreControls extends StatelessWidget {
  const MatchmakerExploreControls({
    super.key,
    required this.searchController,
    required this.genderIndex,
    required this.filterActive,
    required this.onSearchChanged,
    required this.onGenderChanged,
    required this.onFilterTap,
  });

  final TextEditingController searchController;
  final int genderIndex;
  final bool filterActive;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<int> onGenderChanged;
  final VoidCallback onFilterTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        QeranSpacing.s20,
        QeranSpacing.s12,
        QeranSpacing.s12,
        QeranSpacing.s8,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: QeranTextField(
                  controller: searchController,
                  hint: LocaleKeys.matchmaker_explore_search_hint.t(context),
                  prefix: const Icon(
                    Icons.search_rounded,
                    size: 20,
                    color: QeranColors.inkMuted,
                  ),
                  textInputAction: TextInputAction.search,
                  onChanged: onSearchChanged,
                ),
              ),
              IconButton(
                tooltip: LocaleKeys.matchmaker_explore_filter_title.t(context),
                color: QeranColors.wine,
                onPressed: onFilterTap,
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.tune_rounded, size: 24),
                    if (filterActive)
                      const PositionedDirectional(
                        top: -1,
                        end: -1,
                        child: _GoldDot(),
                      ),
                  ],
                ),
              ),
            ],
          ),
          QeranSpacing.vs8,
          MatchmakerSegmentedTabs(
            activeIndex: genderIndex,
            onChanged: onGenderChanged,
            segments: const [
              MatchmakerSegment(
                labelKey: LocaleKeys.matchmaker_explore_gender_all,
              ),
              MatchmakerSegment(
                labelKey: LocaleKeys.matchmaker_explore_gender_male,
              ),
              MatchmakerSegment(
                labelKey: LocaleKeys.matchmaker_explore_gender_female,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GoldDot extends StatelessWidget {
  const _GoldDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: QeranColors.gold,
        shape: BoxShape.circle,
      ),
    );
  }
}
