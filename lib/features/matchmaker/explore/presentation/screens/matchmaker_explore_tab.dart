import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/di/injection_container.dart';
import '../../../../../core/enum/gender.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../../../discovery/domain/entities/discovery_filter_selection.dart';
import '../../../colleagues/presentation/widgets/matchmaker_colleague_open_chat_host.dart';
import '../../../shared/presentation/widgets/matchmaker_app_bar.dart';
import '../blocs/matchmaker_explore_cubit.dart';
import '../blocs/matchmaker_explore_filter_cubit.dart';
import '../widgets/matchmaker_explore_controls.dart';
import '../widgets/matchmaker_explore_list.dart';
import 'matchmaker_explore_filter_sheet.dart';

/// Matchmaker explore tab (S4c) — search + gender + dynamic filters over
/// `GET /matchmaker/explore`, rendered as a paginated list of explore cards.
/// The cubit owns the active query; this screen owns the search debounce, the
/// gender index, and the filter selections (for re-seeding the sheet).
class MatchmakerExploreTab extends StatefulWidget {
  const MatchmakerExploreTab({super.key});

  @override
  State<MatchmakerExploreTab> createState() => _MatchmakerExploreTabState();
}

class _MatchmakerExploreTabState extends State<MatchmakerExploreTab> {
  static const _genders = <Gender?>[null, Gender.male, Gender.female];

  late final MatchmakerExploreCubit _cubit;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  int _genderIndex = 0;
  Map<int, DiscoveryFilterSelection> _selections = const {};

  @override
  void initState() {
    super.initState();
    _cubit = sl<MatchmakerExploreCubit>()..loadFirst();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _cubit.close();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 400),
      () => _cubit.setSearch(value),
    );
  }

  void _onGenderChanged(int index) {
    setState(() => _genderIndex = index);
    _cubit.setGender(_genders[index]);
  }

  Future<void> _onFilterTap() async {
    final result = await showMatchmakerExploreFilterSheet(
      context,
      initialSelections: _selections,
    );
    if (result == null) return; // dismissed — keep current filters
    setState(() => _selections = result);
    _cubit.setQuestionFilters(exploreQuestionFiltersFromSelections(result));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MatchmakerExploreCubit>.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: QeranColors.creamCanvas,
        appBar: MatchmakerAppBar(
          title: LocaleKeys.matchmaker_nav_explore.t(context),
        ),
        body: SafeArea(
          top: false,
          bottom: false,
          // Provides MatchmakerColleagueOpenChatCubit + handles nav/snackbar for
          // the card's matchmaker-chat action (same as the cases tab).
          child: MatchmakerColleagueOpenChatHost(
            child: Column(
              children: [
                MatchmakerExploreControls(
                  searchController: _searchController,
                  genderIndex: _genderIndex,
                  filterActive: _selections.isNotEmpty,
                  onSearchChanged: _onSearchChanged,
                  onGenderChanged: _onGenderChanged,
                  onFilterTap: _onFilterTap,
                ),
                const Expanded(child: MatchmakerExploreList()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
