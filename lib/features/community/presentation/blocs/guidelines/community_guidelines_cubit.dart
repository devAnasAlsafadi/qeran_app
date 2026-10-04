import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/state/safe_emit.dart';
import '../../../domain/entities/guidelines_acceptance.dart';
import '../../../domain/usecases/accept_community_guidelines_usecase.dart';
import '../../../domain/usecases/get_community_guidelines_usecase.dart';
import 'community_guidelines_state.dart';

/// The guidelines step (D7, F5): the server's text (D39), and the member's
/// agreement to the version they read. If the text changed meanwhile, the
/// new one is read and shown, and they're asked again (W3).
class CommunityGuidelinesCubit extends Cubit<CommunityGuidelinesState>
    with SafeEmit<CommunityGuidelinesState> {
  CommunityGuidelinesCubit({
    required GetCommunityGuidelinesUseCase getGuidelines,
    required AcceptCommunityGuidelinesUseCase accept,
    required void Function() onAccepted,
  }) : _getGuidelines = getGuidelines,
       _accept = accept,
       _onAccepted = onAccepted,
       super(const CommunityGuidelinesState());

  final GetCommunityGuidelinesUseCase _getGuidelines;
  final AcceptCommunityGuidelinesUseCase _accept;

  /// Tells the app the guidelines are accepted — the composer's mirror.
  final void Function() _onAccepted;

  Future<void> load() async {
    emit(
      state.copyWith(
        status: CommunityGuidelinesStatus.loading,
        accepting: false,
      ),
    );
    final result = await _getGuidelines();
    result.fold(
      (_) => emit(state.copyWith(status: CommunityGuidelinesStatus.failed)),
      (guidelines) => emit(
        state.copyWith(
          status: CommunityGuidelinesStatus.ready,
          guidelines: guidelines,
        ),
      ),
    );
  }

  /// «أوافق وأتابع»: the version on screen.
  Future<void> accept() async {
    final guidelines = state.guidelines;
    if (!state.canAccept || guidelines == null) return;
    emit(state.copyWith(accepting: true));
    final result = await _accept(guidelines.version);
    await result.fold(
      (_) async => emit(
        state
            .copyWith(accepting: false)
            .withEvent(CommunityGuidelinesEvent.acceptFailed),
      ),
      (answer) => switch (answer) {
        GuidelinesAcceptance.accepted => _accepted(),
        GuidelinesAcceptance.outdated => load(),
      },
    );
  }

  /// Stays "accepting" while the step closes, so nothing is sent twice.
  Future<void> _accepted() async {
    _onAccepted();
    emit(state.withEvent(CommunityGuidelinesEvent.accepted));
  }
}
