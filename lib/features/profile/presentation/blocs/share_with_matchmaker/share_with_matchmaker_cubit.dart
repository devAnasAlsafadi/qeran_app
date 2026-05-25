import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:qeran/core/app_logger.dart';
import 'package:qeran/features/chat/domain/entities/my_matchmaker_outcome.dart';
import 'package:qeran/features/chat/domain/entities/share_profile_outcome.dart';
import 'package:qeran/features/chat/domain/usecases/get_my_matchmaker_usecase.dart';
import 'package:qeran/features/chat/domain/usecases/share_profile_usecase.dart';

import 'share_with_matchmaker_state.dart';

/// Screen-scoped cubit owning the share-with-matchmaker action on the
/// Full Profile Details screen. Resolves the user's matchmaker
/// conversation on init (so the button can render its disabled state
/// when no matchmaker is assigned) and dispatches one-shot outcomes
/// via [ShareWithMatchmakerState.eventVersion].
class ShareWithMatchmakerCubit extends Cubit<ShareWithMatchmakerState> {
  final GetMyMatchmakerUseCase _getMyMatchmaker;
  final ShareProfileUseCase _shareProfile;

  ShareWithMatchmakerCubit({
    required GetMyMatchmakerUseCase getMyMatchmaker,
    required ShareProfileUseCase shareProfile,
  })  : _getMyMatchmaker = getMyMatchmaker,
        _shareProfile = shareProfile,
        super(const ShareWithMatchmakerState.initial());

  /// Looks up the current user's matchmaker conversation. Safe to call
  /// once on screen mount; subsequent calls short-circuit if already
  /// resolved.
  Future<void> resolveMatchmaker() async {
    if (state.resolved) return;
    final result = await _getMyMatchmaker();
    if (isClosed) return;
    result.fold(
      (failure) {
        AppLogger.warning(
          'Resolve matchmaker failed message="${failure.message}"',
          tag: 'PROFILE_SHARE',
        );
        emit(state.copyWith(resolved: true, clearConversationId: true));
      },
      _onOutcome,
    );
  }

  void _onOutcome(MyMatchmakerOutcome outcome) {
    switch (outcome) {
      case MyMatchmakerAssigned(:final info):
        emit(state.copyWith(
          resolved: true,
          conversationId: info.conversationId,
        ));
      case MyMatchmakerNotAssigned():
      case MyMatchmakerFailure():
        emit(state.copyWith(resolved: true, clearConversationId: true));
    }
  }

  /// Tap handler. Fires the share API when a matchmaker is available;
  /// surfaces a typed event otherwise so the screen can show a
  /// localised snackbar.
  Future<void> share(String sharedUserId) async {
    if (state.isSharing) return;
    final convId = state.conversationId;
    if (convId == null) {
      _bumpEvent(ShareEvent.noMatchmaker);
      return;
    }
    emit(state.copyWith(isSharing: true));
    final result = await _shareProfile(
      conversationId: convId,
      sharedUserId: sharedUserId,
    );
    if (isClosed) return;
    result.fold(
      (failure) {
        AppLogger.warning(
          'Share profile failed message="${failure.message}"',
          tag: 'PROFILE_SHARE',
        );
        emit(state.copyWith(isSharing: false));
        _bumpEvent(ShareEvent.failure);
      },
      _onShareOutcome,
    );
  }

  void _onShareOutcome(ShareProfileOutcome outcome) {
    emit(state.copyWith(isSharing: false));
    switch (outcome) {
      case ShareProfileSuccess():
        _bumpEvent(ShareEvent.success);
      case ShareProfileNotFound():
        _bumpEvent(ShareEvent.profileNotFound);
      case ShareProfileValidationError():
        _bumpEvent(ShareEvent.validation);
      case ShareProfileRateLimited():
        _bumpEvent(ShareEvent.rateLimited);
      case ShareProfileConversationNotFound():
        _bumpEvent(ShareEvent.conversationNotFound);
      case ShareProfileUnauthorized():
        _bumpEvent(ShareEvent.unauthorized);
      case ShareProfileFailure():
        _bumpEvent(ShareEvent.failure);
    }
  }

  void _bumpEvent(ShareEvent event) {
    emit(state.copyWith(
      event: event,
      eventVersion: state.eventVersion + 1,
    ));
  }
}
