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

/// Server-backed cases filter, as a single flat single-select list.
///
/// Stage and active-formal-request remain independent parameters that the
/// backend combines before pagination; this sheet just never sends both, since
/// every row is presented as an alternative to every other.
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
  late _CasesFilterChoice _choice;

  @override
  void initState() {
    super.initState();
    _choice = _CasesFilterChoice.from(widget.current);
  }

  void _apply() => Navigator.of(context).pop(_choice.filter);

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
        // One flat list, no section headings: every row is an alternative to
        // every other, so picking one clears whatever was picked before.
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < _CasesFilterChoice.values.length; i++) ...[
              if (i > 0) QeranSpacing.vs8,
              _StageOption(
                label: _CasesFilterChoice.values[i].labelKey.t(context),
                selected: _choice == _CasesFilterChoice.values[i],
                onTap: () =>
                    setState(() => _choice = _CasesFilterChoice.values[i]),
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

/// One row of the flattened filter list, in display order.
///
/// The sheet is single-select, so the two server parameters can never both be
/// set from here: choosing a formal-request row clears any stage and vice
/// versa. The endpoint still accepts them together and combines them before
/// pagination — this UI simply stopped offering that.
enum _CasesFilterChoice {
  all,
  likeAccepted,
  photoPending,
  photoAccepted,
  photoRejected,
  photoExpired,
  formalActive,
  formalInactive;

  /// The query this row stands for. Exactly one parameter, or neither.
  MatchmakerCasesFilter get filter => switch (this) {
    all => const MatchmakerCasesFilter(),
    likeAccepted => const MatchmakerCasesFilter(
      stage: CompatibilityCaseStage.likeAccepted,
    ),
    photoPending => const MatchmakerCasesFilter(
      stage: CompatibilityCaseStage.photoExchangePending,
    ),
    photoAccepted => const MatchmakerCasesFilter(
      stage: CompatibilityCaseStage.photoExchangeAccepted,
    ),
    photoRejected => const MatchmakerCasesFilter(
      stage: CompatibilityCaseStage.photoExchangeRejected,
    ),
    photoExpired => const MatchmakerCasesFilter(
      stage: CompatibilityCaseStage.photoExchangeExpired,
    ),
    formalActive => const MatchmakerCasesFilter(activeFormalRequest: true),
    formalInactive => const MatchmakerCasesFilter(activeFormalRequest: false),
  };

  String get labelKey => switch (this) {
    all => LocaleKeys.matchmaker_cases_filter_all,
    likeAccepted => LocaleKeys.matchmaker_cases_stage_like_accepted,
    photoPending => LocaleKeys.matchmaker_cases_stage_photo_pending,
    photoAccepted => LocaleKeys.matchmaker_cases_stage_photo_accepted,
    photoRejected => LocaleKeys.matchmaker_cases_stage_photo_rejected,
    photoExpired => LocaleKeys.matchmaker_cases_stage_photo_expired,
    formalActive => LocaleKeys.matchmaker_cases_filter_formal_active,
    formalInactive => LocaleKeys.matchmaker_cases_filter_formal_inactive,
  };

  /// The row standing for an existing filter, so reopening the sheet shows
  /// what is applied.
  ///
  /// A filter carrying BOTH parameters has no row — it can only have come from
  /// the two-section sheet this replaced. The stage wins, and applying drops
  /// the formal-request half; that is the single-select contract, not a loss
  /// of state, since the user must press Apply for anything to change.
  static _CasesFilterChoice from(MatchmakerCasesFilter filter) {
    final stage = filter.stage;
    if (stage != null) {
      return switch (stage) {
        CompatibilityCaseStage.likeAccepted => likeAccepted,
        CompatibilityCaseStage.photoExchangePending => photoPending,
        CompatibilityCaseStage.photoExchangeAccepted => photoAccepted,
        CompatibilityCaseStage.photoExchangeRejected => photoRejected,
        CompatibilityCaseStage.photoExchangeExpired => photoExpired,
        CompatibilityCaseStage.unknown => all,
      };
    }
    return switch (filter.activeFormalRequest) {
      true => formalActive,
      false => formalInactive,
      null => all,
    };
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
