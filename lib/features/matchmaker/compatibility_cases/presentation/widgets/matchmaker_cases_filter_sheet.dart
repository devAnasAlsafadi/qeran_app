import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_radii.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../../core/design_system/widgets/qeran_bottom_sheet.dart';
import '../../../../../core/design_system/widgets/qeran_button.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../domain/entities/compatibility_case_stage.dart';
import '../../domain/entities/matchmaker_cases_filter.dart';

/// Server-backed cases filter. Stage and active-formal-request are independent
/// and the backend combines them before pagination.
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
  late CompatibilityCaseStage? _stage;
  late bool? _activeFormalRequest;

  @override
  void initState() {
    super.initState();
    _stage = widget.current.stage;
    _activeFormalRequest = widget.current.activeFormalRequest;
  }

  void _apply() {
    Navigator.of(context).pop(
      MatchmakerCasesFilter(
        stage: _stage,
        activeFormalRequest: _activeFormalRequest,
      ),
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
            Text(
              LocaleKeys.matchmaker_cases_filter_status.t(context),
              style: QeranTypography.subtitle,
            ),
            QeranSpacing.vs8,
            _StageOption(
              label: LocaleKeys.matchmaker_cases_filter_all.t(context),
              selected: _stage == null,
              onTap: () => setState(() => _stage = null),
            ),
            for (final stage in CompatibilityCaseStage.values.where(
              (stage) => stage != CompatibilityCaseStage.unknown,
            )) ...[
              QeranSpacing.vs8,
              _StageOption(
                label: _stageLabelKey(stage).t(context),
                selected: _stage == stage,
                onTap: () => setState(() => _stage = stage),
              ),
            ],
            QeranSpacing.vs24,
            Text(
              LocaleKeys.matchmaker_cases_filter_formal_request.t(context),
              style: QeranTypography.subtitle,
            ),
            QeranSpacing.vs8,
            _StageOption(
              label: LocaleKeys.matchmaker_cases_filter_formal_any.t(context),
              selected: _activeFormalRequest == null,
              onTap: () => setState(() => _activeFormalRequest = null),
            ),
            QeranSpacing.vs8,
            _StageOption(
              label: LocaleKeys.matchmaker_cases_filter_formal_active.t(
                context,
              ),
              selected: _activeFormalRequest == true,
              onTap: () => setState(() => _activeFormalRequest = true),
            ),
            QeranSpacing.vs8,
            _StageOption(
              label: LocaleKeys.matchmaker_cases_filter_formal_inactive.t(
                context,
              ),
              selected: _activeFormalRequest == false,
              onTap: () => setState(() => _activeFormalRequest = false),
            ),
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

String _stageLabelKey(CompatibilityCaseStage stage) => switch (stage) {
  CompatibilityCaseStage.likeAccepted =>
    LocaleKeys.matchmaker_cases_stage_like_accepted,
  CompatibilityCaseStage.photoExchangePending =>
    LocaleKeys.matchmaker_cases_stage_photo_pending,
  CompatibilityCaseStage.photoExchangeAccepted =>
    LocaleKeys.matchmaker_cases_stage_photo_accepted,
  CompatibilityCaseStage.photoExchangeRejected =>
    LocaleKeys.matchmaker_cases_stage_photo_rejected,
  CompatibilityCaseStage.photoExchangeExpired =>
    LocaleKeys.matchmaker_cases_stage_photo_expired,
  CompatibilityCaseStage.unknown => LocaleKeys.matchmaker_cases_filter_all,
};

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
