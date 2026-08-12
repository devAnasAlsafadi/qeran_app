import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../blocs/matchmaker_cases_filter_cubit.dart';
import '../blocs/matchmaker_cases_list_cubit.dart';
import 'matchmaker_cases_filter_sheet.dart';

/// End-aligned filter affordance for the cases tab — the shared app bar can't
/// host it. Opens the bespoke filter sheet and applies the result to the
/// [MatchmakerCasesFilterCubit]; a gold dot marks an active filter.
class MatchmakerCasesFilterBar extends StatelessWidget {
  const MatchmakerCasesFilterBar({super.key, required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        start: QeranSpacing.s20,
        end: QeranSpacing.s12,
        top: QeranSpacing.s4,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IconButton(
            tooltip: LocaleKeys.matchmaker_cases_filter_title.t(context),
            color: QeranColors.wine,
            onPressed: () => _openSheet(context),
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.tune_rounded, size: 24),
                if (isActive)
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
    );
  }

  Future<void> _openSheet(BuildContext context) async {
    final filterCubit = context.read<MatchmakerCasesFilterCubit>();
    final listCubit = context.read<MatchmakerCasesListCubit>();
    final result = await showMatchmakerCasesFilterSheet(
      context,
      current: filterCubit.state,
    );
    if (result == null) return; // dismissed — keep current filter
    filterCubit.apply(result);
    await listCubit.applyFilter(result);
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
