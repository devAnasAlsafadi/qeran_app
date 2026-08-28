import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/app_logger.dart';
import 'package:qeran/core/state/safe_emit.dart';
import 'package:qeran/features/profile/presentation/blocs/profile_gate/profile_gate_cubit.dart';

import '../../domain/usecases/accept_formal_step_usecase.dart';
import '../../domain/usecases/accept_photo_exchange_usecase.dart';
import '../../domain/usecases/cancel_case_usecase.dart';
import '../../domain/usecases/reject_formal_step_usecase.dart';
import '../../domain/usecases/reject_photo_exchange_usecase.dart';
import '../../domain/usecases/request_formal_step_usecase.dart';
import '../../domain/usecases/request_photo_exchange_usecase.dart';
import 'likes_action_events.dart';
import 'likes_refetch_rules.dart';
import 'match_actions_state.dart';

/// Every action taken ON a match card: the photo exchange at stage 0, the
/// formal step at stages 1-2, and cancelling the case at any stage.
///
/// Split from `LikesCubit`, which owns the three tabs and their data. The two
/// separate cleanly because no action here ever READS the matches list — the
/// card comes in as an id from the widget that drew it, and the only thing
/// this cubit needs the list for is telling it to reload afterwards.
///
/// That reload is the one coupling, and it arrives as [reloadMatches] rather
/// than a cubit reference. WHETHER to reload stays where it was put in
/// `likes_refetch_rules.dart`, next to the five other rules it has to stay
/// consistent with; only the doing is injected.
class MatchActionsCubit extends Cubit<MatchActionsState>
    with SafeEmit<MatchActionsState> {
  final RequestPhotoExchangeUseCase _requestPhotoExchange;
  final AcceptPhotoExchangeUseCase _acceptPhotoExchange;
  final RejectPhotoExchangeUseCase _rejectPhotoExchange;
  final RequestFormalStepUseCase _requestFormalStep;
  final AcceptFormalStepUseCase _acceptFormalStep;
  final RejectFormalStepUseCase _rejectFormalStep;
  final CancelCaseUseCase _cancelCase;
  final ProfileGateCubit _profileGate;

  /// Refetches the matches list. Supplied by whoever owns it.
  final Future<void> Function() _reloadMatches;

  MatchActionsCubit({
    required RequestPhotoExchangeUseCase requestPhotoExchange,
    required AcceptPhotoExchangeUseCase acceptPhotoExchange,
    required RejectPhotoExchangeUseCase rejectPhotoExchange,
    required RequestFormalStepUseCase requestFormalStep,
    required AcceptFormalStepUseCase acceptFormalStep,
    required RejectFormalStepUseCase rejectFormalStep,
    required CancelCaseUseCase cancelCase,
    required ProfileGateCubit profileGate,
    required Future<void> Function() reloadMatches,
  }) : _requestPhotoExchange = requestPhotoExchange,
       _acceptPhotoExchange = acceptPhotoExchange,
       _rejectPhotoExchange = rejectPhotoExchange,
       _requestFormalStep = requestFormalStep,
       _acceptFormalStep = acceptFormalStep,
       _rejectFormalStep = rejectFormalStep,
       _cancelCase = cancelCase,
       _profileGate = profileGate,
       _reloadMatches = reloadMatches,
       super(const MatchActionsState());

  void _emitAction(MatchActionEvent event) {
    emit(
      state.copyWith(event: event, eventVersion: state.eventVersion + 1),
    );
  }

  Future<void> requestPhotoExchange(int likeRequestId) async {
    if (state.isPhotoRequesting(likeRequestId)) return;
    // Approval pre-gate — an unapproved user can't request photo exchange yet.
    if (_profileGate.isGated) {
      emit(
        state.copyWith(
          event: MatchActionEvent.photoRequestUnderReview,
          eventVersion: state.eventVersion + 1,
        ),
      );
      return;
    }
    emit(
      state.copyWith(
        photoRequestInFlightLikeIds: {
          ...state.photoRequestInFlightLikeIds,
          likeRequestId,
        },
      ),
    );
    final result = await _requestPhotoExchange(likeRequestId);
    if (isClosed) return;
    final MatchActionEvent event = result.fold((failure) {
      AppLogger.warning(
        'PHOTO-EXCHANGE — request transport failure id=$likeRequestId '
        'raw="${failure.message}"',
        tag: 'MATCHES',
      );
      return MatchActionEvent.photoRequestFailure;
    }, photoExchangeRequestEvent);
    final cleared = {...state.photoRequestInFlightLikeIds}
      ..remove(likeRequestId);
    emit(
      state.copyWith(
        photoRequestInFlightLikeIds: cleared,
        event: event,
        eventVersion: state.eventVersion + 1,
      ),
    );
    if (refetchMatchesAfterPhotoRequest(event)) {
      await _reloadMatches();
    }
  }

  Future<void> acceptPhotoExchange(int requestId) async {
    if (state.isPhotoResponding(requestId)) return;
    emit(
      state.copyWith(
        photoAcceptInFlightRequestIds: {
          ...state.photoAcceptInFlightRequestIds,
          requestId,
        },
      ),
    );
    final result = await _acceptPhotoExchange(requestId);
    if (isClosed) return;
    final MatchActionEvent event = result.fold((failure) {
      AppLogger.warning(
        'PHOTO-EXCHANGE — accept transport failure requestId=$requestId '
        'raw="${failure.message}"',
        tag: 'MATCHES',
      );
      return MatchActionEvent.photoRespondFailure;
    }, (outcome) => photoExchangeRespondEvent(outcome, isAccept: true));
    final cleared = {...state.photoAcceptInFlightRequestIds}
      ..remove(requestId);
    emit(
      state.copyWith(
        photoAcceptInFlightRequestIds: cleared,
        event: event,
        eventVersion: state.eventVersion + 1,
      ),
    );
    if (refetchMatchesAfterPhotoRespond(event)) {
      await _reloadMatches();
    }
  }

  Future<void> rejectPhotoExchange(int requestId) async {
    if (state.isPhotoResponding(requestId)) return;
    emit(
      state.copyWith(
        photoRejectInFlightRequestIds: {
          ...state.photoRejectInFlightRequestIds,
          requestId,
        },
      ),
    );
    final result = await _rejectPhotoExchange(requestId);
    if (isClosed) return;
    final MatchActionEvent event = result.fold((failure) {
      AppLogger.warning(
        'PHOTO-EXCHANGE — reject transport failure requestId=$requestId '
        'raw="${failure.message}"',
        tag: 'MATCHES',
      );
      return MatchActionEvent.photoRespondFailure;
    }, (outcome) => photoExchangeRespondEvent(outcome, isAccept: false));
    final cleared = {...state.photoRejectInFlightRequestIds}
      ..remove(requestId);
    emit(
      state.copyWith(
        photoRejectInFlightRequestIds: cleared,
        event: event,
        eventVersion: state.eventVersion + 1,
      ),
    );
    if (refetchMatchesAfterPhotoRespond(event)) {
      await _reloadMatches();
    }
  }

  /// Open the journey on one match card, or pass null to close whichever is
  /// open. At most one is ever open: a second open card would push the first
  /// one's timeline off screen anyway, and the list would grow by the height
  /// of a card for every one left behind.
  void openJourney(int? likeRequestId) {
    if (state.openJourneyLikeRequestId == likeRequestId) return;
    emit(
      likeRequestId == null
          ? state.copyWith(clearOpenJourney: true)
          : state.copyWith(openJourneyLikeRequestId: likeRequestId),
    );
  }

  /// Asks the OTHER MEMBER to begin the formal step.
  ///
  /// It shares nothing into the matchmaker chat, and that removal is the
  /// point of this method rather than a simplification of it. The matchmaker
  /// has no role until the receiver approves — that is when the server creates
  /// the `FormalRequest` and moves the case to `AwaitingMatchmakerCoordination`
  /// — so posting a card and a message on REQUEST told her about something
  /// that might be declined. The stage-0 inquiry still shares, because it
  /// genuinely is a message to her; it lives in `MatchmakerInquiryCubit`.
  ///
  /// That guarantee is now STRUCTURAL rather than tested. This cubit holds no
  /// chat use case at all, so there is nothing here to post with — restoring
  /// the old behaviour would mean re-injecting three dependencies and a DI
  /// registration, which is a decision rather than a slip. The test that
  /// checked it at runtime was deleted for that reason.
  Future<void> sendFormalStep(int likeRequestId) async {
    if (state.isFormalStepSending(likeRequestId)) return;
    // Approval pre-gate, as on photo exchange: PROFILE_NOT_APPROVED is a
    // documented answer here, and asking a question we already know the
    // answer to costs a round trip.
    if (_profileGate.isGated) {
      _emitAction(MatchActionEvent.formalStepUnderReview);
      return;
    }

    emit(
      state.copyWith(
        formalStepInFlightLikeIds: {
          ...state.formalStepInFlightLikeIds,
          likeRequestId,
        },
      ),
    );
    final result = await _requestFormalStep(likeRequestId);
    if (isClosed) return;

    final MatchActionEvent event = result.fold((failure) {
      AppLogger.warning(
        'FORMAL-STEP — request transport failure id=$likeRequestId '
        'raw="${failure.message}"',
        tag: 'MATCHES',
      );
      return MatchActionEvent.formalStepFailure;
    }, formalStepRequestEvent);

    final cleared = {...state.formalStepInFlightLikeIds}..remove(likeRequestId);
    emit(
      state.copyWith(
        formalStepInFlightLikeIds: cleared,
        event: event,
        eventVersion: state.eventVersion + 1,
      ),
    );
    if (refetchMatchesAfterFormalRequest(event)) {
      await _reloadMatches();
    }
  }

  /// Agrees to begin the formal step. Takes `pendingFormalStep.id`.
  ///
  /// On success the server creates the `FormalRequest` and moves the case to
  /// `AwaitingMatchmakerCoordination` — this is the moment the matchmaker
  /// first hears about any of it.
  Future<void> acceptFormalStep(int requestId) =>
      _respondToFormalStep(requestId, isAccept: true);

  /// Declines, which ENDS the compatibility case. The caller confirms first.
  Future<void> rejectFormalStep(int requestId) =>
      _respondToFormalStep(requestId, isAccept: false);

  /// Both answers, one body.
  ///
  /// They differ in the use case they call, the set they hold the id in, and
  /// the event a success reports. Every failure path is identical, which is
  /// also why `FormalStepRespondOutcome` is one family: keeping two copies of
  /// this would mean two chances to classify the same refusal differently.
  ///
  /// No approval pre-gate, unlike `sendFormalStep`. Answering a request
  /// someone already sent you is not a new outward action, so the server does
  /// not gate it on profile approval and neither does this.
  Future<void> _respondToFormalStep(
    int requestId, {
    required bool isAccept,
  }) async {
    // Guards on EITHER answer in flight, not just this one. A card whose
    // accept is mid-flight must not also be able to send a reject.
    if (state.isFormalStepResponding(requestId)) return;

    final verb = isAccept ? 'accept' : 'reject';
    emit(
      isAccept
          ? state.copyWith(
              formalStepAcceptInFlightRequestIds: {
                ...state.formalStepAcceptInFlightRequestIds,
                requestId,
              },
            )
          : state.copyWith(
              formalStepRejectInFlightRequestIds: {
                ...state.formalStepRejectInFlightRequestIds,
                requestId,
              },
            ),
    );

    final result = isAccept
        ? await _acceptFormalStep(requestId)
        : await _rejectFormalStep(requestId);
    if (isClosed) return;

    final MatchActionEvent event = result.fold((failure) {
      AppLogger.warning(
        'FORMAL-STEP — $verb transport failure requestId=$requestId '
        'raw="${failure.message}"',
        tag: 'MATCHES',
      );
      return MatchActionEvent.formalStepRespondFailure;
    }, (outcome) => formalStepRespondEvent(outcome, isAccept: isAccept));

    emit(
      isAccept
          ? state.copyWith(
              formalStepAcceptInFlightRequestIds:
                  {...state.formalStepAcceptInFlightRequestIds}
                    ..remove(requestId),
              event: event,
              eventVersion: state.eventVersion + 1,
            )
          : state.copyWith(
              formalStepRejectInFlightRequestIds:
                  {...state.formalStepRejectInFlightRequestIds}
                    ..remove(requestId),
              event: event,
              eventVersion: state.eventVersion + 1,
            ),
    );
    if (refetchMatchesAfterFormalRespond(event)) {
      await _reloadMatches();
    }
  }

  /// Ends the whole compatibility case. Takes the LIKE id, not a request id —
  /// this acts on the case, not on anything inside it. The caller confirms
  /// first.
  ///
  /// Deliberately has no profile-approval pre-gate, unlike [sendFormalStep].
  /// That gate exists because requesting the formal step is a new outward
  /// approach to someone; withdrawing from a case you are already in is not,
  /// and the server does not gate it either.
  ///
  /// The other member is told, but not by us: the server pushes the same
  /// neutral notice it sends when a formal step is declined, naming no actor.
  Future<void> cancelCase(int likeRequestId) async {
    if (state.isCancelling(likeRequestId)) return;

    emit(
      state.copyWith(
        cancelInFlightLikeIds: {...state.cancelInFlightLikeIds, likeRequestId},
      ),
    );

    final result = await _cancelCase(likeRequestId);
    if (isClosed) return;

    final MatchActionEvent event = result.fold((failure) {
      AppLogger.warning(
        'CASE-CANCEL — transport failure likeRequestId=$likeRequestId '
        'raw="${failure.message}"',
        tag: 'MATCHES',
      );
      return MatchActionEvent.cancelFailure;
    }, caseCancelEvent);

    emit(
      state.copyWith(
        cancelInFlightLikeIds: {...state.cancelInFlightLikeIds}
          ..remove(likeRequestId),
        event: event,
        eventVersion: state.eventVersion + 1,
      ),
    );
    if (refetchMatchesAfterCancel(event)) {
      await _reloadMatches();
    }
  }
}
