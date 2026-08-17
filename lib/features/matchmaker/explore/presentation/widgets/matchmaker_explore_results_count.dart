import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../core/state/paginated_list_state.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../domain/entities/matchmaker_explore_user.dart';
import '../blocs/matchmaker_explore_cubit.dart';

/// "N results found", above the explore list.
///
/// Renders only when the server reported a total AND that total is positive.
/// Null means the backend did not send one, so any number would be invented.
/// Zero is left to the list's own empty state — a "found 0 results" line
/// stacked above "no results" says the same thing twice.
class MatchmakerExploreResultsCount extends StatelessWidget {
  const MatchmakerExploreResultsCount({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<
      MatchmakerExploreCubit,
      PaginatedListState<MatchmakerExploreUser>
    >(
      buildWhen: (a, b) => a.totalCount != b.totalCount,
      builder: (context, state) {
        final total = state.totalCount;
        if (total == null || total <= 0) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            QeranSpacing.s20,
            0,
            QeranSpacing.s20,
            QeranSpacing.s8,
          ),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              LocaleKeys.filters_results_count.t(
                context,
                namedArgs: {'count': '$total'},
              ),
              style: QeranTypography.caption.copyWith(
                color: QeranColors.inkMuted,
              ),
            ),
          ),
        );
      },
    );
  }
}
