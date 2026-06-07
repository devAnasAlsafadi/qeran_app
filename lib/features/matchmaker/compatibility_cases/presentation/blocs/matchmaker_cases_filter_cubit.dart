import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/matchmaker_cases_filter.dart';

/// Thin holder for the client-side cases filter. Kept separate from
/// [MatchmakerCasesListCubit] so the paginated list state is untouched — the
/// tab combines this filter with the loaded items to derive the visible list.
class MatchmakerCasesFilterCubit extends Cubit<MatchmakerCasesFilter> {
  MatchmakerCasesFilterCubit() : super(const MatchmakerCasesFilter());

  void apply(MatchmakerCasesFilter filter) => emit(filter);

  void clear() => emit(const MatchmakerCasesFilter());
}
