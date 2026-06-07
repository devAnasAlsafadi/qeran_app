import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_radii.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../../core/design_system/widgets/qeran_button.dart';
import '../../../../../core/design_system/widgets/qeran_sheet_handle.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../../../discovery/domain/entities/discovery_filter_option.dart';
import '../../../../discovery/domain/entities/discovery_filter_question.dart';
import '../../../../discovery/domain/entities/discovery_filter_selection.dart';
import '../../../../discovery/domain/entities/filter_question_type.dart';
import '../../../../discovery/presentation/widgets/filter_expandable_multi.dart';
import '../../../../discovery/presentation/widgets/filter_text_field.dart';
import '../../domain/entities/formal_request_status.dart';
import '../../domain/entities/matchmaker_cases_filter.dart';
import 'matchmaker_case_labels.dart';

/// The 5 selectable statuses, in the wire/transition order.
const List<FormalRequestStatus> _filterableStatuses = [
  FormalRequestStatus.waitingForParentAppointment,
  FormalRequestStatus.parentsVisited,
  FormalRequestStatus.successfullyClosed,
  FormalRequestStatus.compatibilityClosed,
  FormalRequestStatus.compatibilityCancelled,
];

/// Bespoke cases-filter bottom sheet. The chrome (handle + title + apply/clear)
/// is matchmaker-scoped; the two controls REUSE the discovery filter
/// sub-widgets ([FilterExpandableMulti] for the status multi-select,
/// [FilterTextField] for name search) by feeding them synthetic
/// [DiscoveryFilterQuestion]s — they're callback-driven, so no discovery state
/// is touched. Returns the chosen [MatchmakerCasesFilter] on apply, or `null`
/// if dismissed; the dedicated "clear" button returns an empty filter.
Future<MatchmakerCasesFilter?> showMatchmakerCasesFilterSheet(
  BuildContext context, {
  required MatchmakerCasesFilter current,
}) {
  return showModalBottomSheet<MatchmakerCasesFilter>(
    context: context,
    isScrollControlled: true,
    backgroundColor: QeranColors.paper,
    shape: const RoundedRectangleBorder(borderRadius: QeranRadii.domeTop),
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
  late Set<FormalRequestStatus> _statuses;
  late String _nameQuery;

  @override
  void initState() {
    super.initState();
    _statuses = {...widget.current.statuses};
    _nameQuery = widget.current.nameQuery;
  }

  void _toggleStatus(String enumName) {
    final status = FormalRequestStatus.values
        .firstWhere((s) => s.name == enumName, orElse: () => FormalRequestStatus.unknown);
    if (status == FormalRequestStatus.unknown) return;
    setState(() {
      _statuses.contains(status)
          ? _statuses.remove(status)
          : _statuses.add(status);
    });
  }

  DiscoveryFilterQuestion _statusQuestion(BuildContext context) {
    return DiscoveryFilterQuestion(
      id: 0,
      label: LocaleKeys.matchmaker_cases_filter_status.t(context),
      type: FilterQuestionType.checkbox,
      isRange: false,
      options: [
        for (final s in _filterableStatuses)
          DiscoveryFilterOption(
            value: s.name,
            display: (formalStatusLabelKey(s) ?? '').t(context),
          ),
      ],
    );
  }

  DiscoveryFilterQuestion _nameQuestion(BuildContext context) {
    return DiscoveryFilterQuestion(
      id: 1,
      label: LocaleKeys.matchmaker_cases_filter_name.t(context),
      type: FilterQuestionType.text,
      isRange: false,
    );
  }

  void _apply() {
    Navigator.of(context).pop(
      MatchmakerCasesFilter(statuses: _statuses, nameQuery: _nameQuery.trim()),
    );
  }

  void _clear() => Navigator.of(context).pop(const MatchmakerCasesFilter());

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        QeranSpacing.s20,
        QeranSpacing.s12,
        QeranSpacing.s20,
        QeranSpacing.s20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: QeranSheetHandle()),
          QeranSpacing.vs16,
          Text(
            LocaleKeys.matchmaker_cases_filter_title.t(context),
            style: QeranTypography.title,
          ),
          QeranSpacing.vs16,
          FilterExpandableMulti(
            question: _statusQuestion(context),
            selection:
                MultiValueSelection(_statuses.map((s) => s.name).toList()),
            onToggle: _toggleStatus,
          ),
          QeranSpacing.vs12,
          FilterTextField(
            question: _nameQuestion(context),
            selection:
                _nameQuery.isEmpty ? null : SingleValueSelection(_nameQuery),
            onChanged: (v) => _nameQuery = v,
          ),
          QeranSpacing.vs20,
          QeranButton(
            label: LocaleKeys.matchmaker_cases_filter_apply.t(context),
            variant: QeranButtonVariant.primaryWine,
            onPressed: _apply,
          ),
          QeranSpacing.vs8,
          QeranButton(
            label: LocaleKeys.matchmaker_cases_filter_clear.t(context),
            variant: QeranButtonVariant.ghost,
            onPressed: _clear,
          ),
        ],
      ),
    );
  }
}
