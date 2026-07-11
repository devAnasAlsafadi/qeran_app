import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_radii.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../../core/design_system/widgets/qeran_bottom_sheet.dart';
import '../../../../../core/design_system/widgets/qeran_button.dart';
import '../../../../../core/design_system/widgets/qeran_text_field.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../domain/entities/case_stage.dart';
import '../../domain/entities/matchmaker_cases_filter.dart';
import 'case_timeline.dart';

/// The cases filter sheet (08): a name search + a single-select stage list
/// (`الكل` + the five canonical [CaseStage]s, labelled from the SAME shared
/// source as the detail timeline). Returns the chosen [MatchmakerCasesFilter]
/// on apply, an empty filter from "مسح", or `null` if dismissed.
Future<MatchmakerCasesFilter?> showMatchmakerCasesFilterSheet(
  BuildContext context, {
  required MatchmakerCasesFilter current,
}) {
  return showQeranBottomSheet<MatchmakerCasesFilter>(
    context: context,
    builder: (_) => _CasesFilterSheet(current: current),
  );
}

class _CasesFilterSheet extends StatefulWidget {
  const _CasesFilterSheet({required this.current});

  final MatchmakerCasesFilter current;

  @override
  State<_CasesFilterSheet> createState() => _CasesFilterSheetState();
}

class _CasesFilterSheetState extends State<_CasesFilterSheet> {
  late CaseStage? _stage;
  late final TextEditingController _name;

  @override
  void initState() {
    super.initState();
    _stage = widget.current.stage;
    _name = TextEditingController(text: widget.current.nameQuery);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _apply() {
    Navigator.of(context).pop(
      MatchmakerCasesFilter(stage: _stage, nameQuery: _name.text.trim()),
    );
  }

  void _clear() => Navigator.of(context).pop(const MatchmakerCasesFilter());

  @override
  Widget build(BuildContext context) {
    return QeranBottomSheetScaffold(
      title: LocaleKeys.matchmaker_cases_filter_title.t(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          QeranSpacing.s20,
          QeranSpacing.s4,
          QeranSpacing.s20,
          QeranSpacing.s16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            QeranTextField(
              controller: _name,
              hint: LocaleKeys.matchmaker_cases_filter_name.t(context),
              prefix: const Icon(
                Icons.search_rounded,
                size: 20,
                color: QeranColors.inkMuted,
              ),
              onChanged: (_) {},
            ),
            QeranSpacing.vs16,
            // الكل + the canonical stages, single-select.
            _StageOption(
              label: LocaleKeys.matchmaker_cases_filter_all.t(context),
              selected: _stage == null,
              onTap: () => setState(() => _stage = null),
            ),
            for (final stage in CaseStage.values) ...[
              QeranSpacing.vs8,
              _StageOption(
                label: caseStageLabelKey(stage).t(context),
                selected: _stage == stage,
                onTap: () => setState(() => _stage = stage),
              ),
            ],
          ],
        ),
      ),
      footer: Padding(
        padding: const EdgeInsets.fromLTRB(
          QeranSpacing.s20,
          QeranSpacing.s8,
          QeranSpacing.s20,
          QeranSpacing.s16,
        ),
        child: Row(
          children: [
            Expanded(
              child: QeranButton(
                label: LocaleKeys.matchmaker_cases_filter_clear.t(context),
                variant: QeranButtonVariant.ghost,
                onPressed: _clear,
              ),
            ),
            QeranSpacing.hs12,
            Expanded(
              flex: 2,
              child: QeranButton(
                label: LocaleKeys.matchmaker_cases_filter_apply.t(context),
                variant: QeranButtonVariant.primary,
                onPressed: _apply,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One single-select stage row — gold border + cream-surface + a gold-deep
/// check when selected; paper + wine-08 border otherwise.
class _StageOption extends StatelessWidget {
  const _StageOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? QeranColors.creamSurface : QeranColors.paper,
      borderRadius: QeranRadii.controlR,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: QeranSpacing.s16,
            vertical: QeranSpacing.s12,
          ),
          decoration: BoxDecoration(
            borderRadius: QeranRadii.controlR,
            border: Border.all(
              color: selected ? QeranColors.gold : QeranColors.wine08,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: QeranTypography.subtitle.copyWith(
                    color: QeranColors.inkStrong,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              if (selected)
                const Icon(
                  Icons.check_circle_rounded,
                  size: 20,
                  color: QeranColors.goldDeep,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
