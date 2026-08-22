import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/state/safe_emit.dart';

import 'package:qeran/core/app_logger.dart';
import 'package:qeran/features/chat/domain/entities/my_matchmaker_outcome.dart';
import 'package:qeran/features/chat/domain/entities/send_text_outcome.dart';
import 'package:qeran/features/chat/domain/entities/share_profile_outcome.dart';
import 'package:qeran/features/chat/domain/usecases/get_my_matchmaker_usecase.dart';
import 'package:qeran/features/chat/domain/usecases/send_text_message_usecase.dart';
import 'package:qeran/features/chat/domain/usecases/share_profile_usecase.dart';
import 'package:qeran/features/profile/presentation/blocs/profile_gate/profile_gate_cubit.dart';

import '../../domain/entities/like_action_outcome.dart';
import '../../domain/entities/likes_tab.dart';
import '../../domain/entities/match_card.dart';
import '../../domain/entities/photo_exchange_outcome.dart';
import '../../domain/usecases/accept_like_usecase.dart';
import '../../domain/usecases/accept_photo_exchange_usecase.dart';
import '../../domain/usecases/get_incoming_likes_usecase.dart';
import '../../domain/usecases/get_matches_usecase.dart';
import '../../domain/usecases/get_outgoing_likes_usecase.dart';
import '../../domain/usecases/reject_like_usecase.dart';
import '../../domain/usecases/reject_photo_exchange_usecase.dart';
import '../../domain/usecases/request_photo_exchange_usecase.dart';
import 'likes_state.dart';

/// Screen-scoped controller for the Likes / Interests tabs (Sent /
/// Received / Matches).
///
/// Each tab is an independent async slot in [LikesState]; switching is
/// instant once a tab has loaded, and one tab can be in `failure` while
/// the others are in `loaded`. Tabs load lazily — their loader fires
/// the first time the user activates the tab, then the result is
/// cached until pull-to-refresh.
///
/// **Cross-tab freshness**: when a Received-tab `acceptLike` succeeds,
/// the matches slot is invalidated back to `initial` so the next visit
/// refetches and the new Stage-0 match shows up.
class LikesCubit extends Cubit<LikesState> with SafeEmit<LikesState> {
  final GetIncomingLikesUseCase _getIncoming;
  final GetOutgoingLikesUseCase _getOutgoing;
  final AcceptLikeUseCase _acceptLike;
  final RejectLikeUseCase _rejectLike;
  final GetMatchesUseCase _getMatches;
  final RequestPhotoExchangeUseCase _requestPhotoExchange;
  final AcceptPhotoExchangeUseCase _acceptPhotoExchange;
  final RejectPhotoExchangeUseCase _rejectPhotoExchange;
  // Chat use-cases (cross-feature) for inquiry / formal-step auto-send.
  final GetMyMatchmakerUseCase _getMyMatchmaker;
  final ShareProfileUseCase _shareProfile;
  final SendTextMessageUseCase _sendText;
  final ProfileGateCubit _profileGate;

  LikesCubit({
    required GetIncomingLikesUseCase getIncoming,
    required GetOutgoingLikesUseCase getOutgoing,
    required AcceptLikeUseCase acceptLike,
    required RejectLikeUseCase rejectLike,
    required GetMatchesUseCase getMatches,
    required RequestPhotoExchangeUseCase requestPhotoExchange,
    required AcceptPhotoExchangeUseCase acceptPhotoExchange,
    required RejectPhotoExchangeUseCase rejectPhotoExchange,
    required GetMyMatchmakerUseCase getMyMatchmaker,
    required ShareProfileUseCase shareProfile,
    required SendTextMessageUseCase sendText,
    required ProfileGateCubit profileGate,
  }) : _getIncoming = getIncoming,
       _getOutgoing = getOutgoing,
       _acceptLike = acceptLike,
       _rejectLike = rejectLike,
       _getMatches = getMatches,
       _requestPhotoExchange = requestPhotoExchange,
       _acceptPhotoExchange = acceptPhotoExchange,
       _rejectPhotoExchange = rejectPhotoExchange,
       _getMyMatchmaker = getMyMatchmaker,
       _shareProfile = shareProfile,
       _sendText = sendText,
       _profileGate = profileGate,
       super(const LikesState());

  /// Kicks off the active tab if it hasn't loaded yet. Called once
  /// when the screen mounts so the user sees data without an extra tap.
  void primeActiveTab() {
    switch (state.activeTab) {
      case LikesTab.sent:
        if (state.outgoingStatus == LikesAsyncStatus.initial) loadOutgoing();
      case LikesTab.received:
        if (state.incomingStatus == LikesAsyncStatus.initial) loadIncoming();
      case LikesTab.matches:
        if (state.matchesStatus == LikesAsyncStatus.initial) loadMatches();
    }
  }

  void switchTab(LikesTab tab) {
    if (state.activeTab == tab) return;
    emit(state.copyWith(activeTab: tab));
    // Lazy-load the tab the user just opened, the first time only.
    switch (tab) {
      case LikesTab.sent:
        if (state.outgoingStatus == LikesAsyncStatus.initial) loadOutgoing();
      case LikesTab.received:
        if (state.incomingStatus == LikesAsyncStatus.initial) loadIncoming();
      case LikesTab.matches:
        if (state.matchesStatus == LikesAsyncStatus.initial) loadMatches();
    }
  }

  Future<void> loadIncoming() async {
    emit(
      state.copyWith(
        incomingStatus: LikesAsyncStatus.loading,
        clearIncomingError: true,
      ),
    );
    final result = await _getIncoming();
    if (isClosed) return;
    result.fold(
      (failure) {
        // The raw `failure.message` is whatever the data source / HTTP
        // layer threw — possibly a raw English token like "Operation
        // Failed". We log it for engineering follow-up but never push
        // it through `.tr()`; the UI uses localized generic copy.
        AppLogger.warning(
          'Incoming likes failed — raw="${failure.message}"',
          tag: 'LIKES',
        );
        emit(
          state.copyWith(
            incomingStatus: LikesAsyncStatus.failure,
            incomingErrorKey: failure.message,
          ),
        );
      },
      (data) => emit(
        state.copyWith(
          incomingStatus: LikesAsyncStatus.loaded,
          incoming: data,
          clearIncomingError: true,
        ),
      ),
    );
  }

  Future<void> loadOutgoing() async {
    emit(
      state.copyWith(
        outgoingStatus: LikesAsyncStatus.loading,
        clearOutgoingError: true,
      ),
    );
    final result = await _getOutgoing();
    if (isClosed) return;
    result.fold(
      (failure) {
        AppLogger.warning(
          'Outgoing likes failed — raw="${failure.message}"',
          tag: 'LIKES',
        );
        emit(
          state.copyWith(
            outgoingStatus: LikesAsyncStatus.failure,
            outgoingErrorKey: failure.message,
          ),
        );
      },
      (data) => emit(
        state.copyWith(
          outgoingStatus: LikesAsyncStatus.loaded,
          outgoing: data,
          clearOutgoingError: true,
        ),
      ),
    );
  }

  Future<void> loadMatches() async {
    emit(
      state.copyWith(
        matchesStatus: LikesAsyncStatus.loading,
        clearMatchesError: true,
      ),
    );
    final result = await _getMatches();
    if (isClosed) return;
    result.fold(
      (failure) {
        AppLogger.warning(
          'Matches failed — raw="${failure.message}"',
          tag: 'MATCHES',
        );
        emit(
          state.copyWith(
            matchesStatus: LikesAsyncStatus.failure,
            matchesErrorKey: failure.message,
          ),
        );
      },
      (data) => emit(
        state.copyWith(
          matchesStatus: LikesAsyncStatus.loaded,
          matches: data,
          clearMatchesError: true,
        ),
      ),
    );
  }

  /// Pull-to-refresh entry for the active tab. Always forces a fetch.
  Future<void> refresh() {
    switch (state.activeTab) {
      case LikesTab.sent:
        return loadOutgoing();
      case LikesTab.received:
        return loadIncoming();
      case LikesTab.matches:
        return loadMatches();
    }
  }

  // ── Like accept / reject ────────────────────────────────────────────

  Future<void> acceptLike(int likeRequestId) async {
    if (state.isActionInFlight(likeRequestId)) return;
    // Approval pre-gate — an unapproved user can't accept likes yet.
    if (_profileGate.isGated) {
      emit(
        state.copyWith(
          actionEvent: LikesActionEvent.acceptUnderReview,
          actionEventVersion: state.actionEventVersion + 1,
        ),
      );
      return;
    }
    emit(
      state.copyWith(
        acceptInFlightIds: {...state.acceptInFlightIds, likeRequestId},
      ),
    );
    final result = await _acceptLike(likeRequestId);
    if (isClosed) return;
    final LikesActionEvent event = result.fold((failure) {
      AppLogger.warning(
        'LIKES — accept transport failure id=$likeRequestId '
        'raw="${failure.message}"',
        tag: 'LIKES',
      );
      return LikesActionEvent.acceptFailure;
    }, _accept);
    final clearedAccept = {...state.acceptInFlightIds}..remove(likeRequestId);
    // On accept success the matches list will get a new Stage-0 row —
    // invalidate the matches slot so the next tab visit refetches.
    final invalidateMatches = event == LikesActionEvent.acceptSuccess;
    emit(
      state.copyWith(
        acceptInFlightIds: clearedAccept,
        actionEvent: event,
        actionEventVersion: state.actionEventVersion + 1,
        resetMatchesToInitial: invalidateMatches,
      ),
    );
    if (_shouldRefreshIncomingAfterLikeAction(event)) {
      await loadIncoming();
    }
  }

  Future<void> rejectLike(int likeRequestId) async {
    if (state.isActionInFlight(likeRequestId)) return;
    emit(
      state.copyWith(
        rejectInFlightIds: {...state.rejectInFlightIds, likeRequestId},
      ),
    );
    final result = await _rejectLike(likeRequestId);
    if (isClosed) return;
    final LikesActionEvent event = result.fold((failure) {
      AppLogger.warning(
        'LIKES — reject transport failure id=$likeRequestId '
        'raw="${failure.message}"',
        tag: 'LIKES',
      );
      return LikesActionEvent.rejectFailure;
    }, _reject);
    final clearedReject = {...state.rejectInFlightIds}..remove(likeRequestId);
    emit(
      state.copyWith(
        rejectInFlightIds: clearedReject,
        actionEvent: event,
        actionEventVersion: state.actionEventVersion + 1,
      ),
    );
    if (_shouldRefreshIncomingAfterLikeAction(event)) {
      await loadIncoming();
    }
  }

  LikesActionEvent _accept(LikeActionOutcome outcome) {
    return switch (outcome) {
      LikeActionSuccess() => LikesActionEvent.acceptSuccess,
      LikeActionRequiresSubscription() =>
        LikesActionEvent.acceptRequiresSubscription,
      LikeActionExpired() => LikesActionEvent.acceptExpired,
      LikeActionNotFoundOrExpired() => LikesActionEvent.acceptNotFound,
      LikeActionProfileUnderReview() => LikesActionEvent.acceptUnderReview,
      LikeActionFailure() => LikesActionEvent.acceptFailure,
    };
  }

  LikesActionEvent _reject(LikeActionOutcome outcome) {
    return switch (outcome) {
      LikeActionSuccess() => LikesActionEvent.rejectSuccess,
      // Reject is never subscription-gated server-side; treat it as
      // generic failure rather than opening the paywall.
      LikeActionRequiresSubscription() => LikesActionEvent.rejectFailure,
      LikeActionExpired() => LikesActionEvent.rejectExpired,
      LikeActionNotFoundOrExpired() => LikesActionEvent.rejectNotFound,
      // Reject is never approval-gated server-side; treat an under-review
      // result as a generic failure rather than surfacing "under review".
      LikeActionProfileUnderReview() => LikesActionEvent.rejectFailure,
      LikeActionFailure() => LikesActionEvent.rejectFailure,
    };
  }

  bool _shouldRefreshIncomingAfterLikeAction(LikesActionEvent event) {
    return switch (event) {
      LikesActionEvent.acceptSuccess ||
      LikesActionEvent.acceptExpired ||
      LikesActionEvent.acceptNotFound ||
      LikesActionEvent.rejectSuccess ||
      LikesActionEvent.rejectExpired ||
      LikesActionEvent.rejectNotFound => true,
      _ => false,
    };
  }

  // ── Photo exchange — initiator (request) ───────────────────────────

  Future<void> requestPhotoExchange(int likeRequestId) async {
    if (state.isPhotoExchangeRequesting(likeRequestId)) return;
    // Approval pre-gate — an unapproved user can't request photo exchange yet.
    if (_profileGate.isGated) {
      emit(
        state.copyWith(
          actionEvent: LikesActionEvent.photoExchangeRequestUnderReview,
          actionEventVersion: state.actionEventVersion + 1,
        ),
      );
      return;
    }
    emit(
      state.copyWith(
        photoExchangeRequestInFlightLikeIds: {
          ...state.photoExchangeRequestInFlightLikeIds,
          likeRequestId,
        },
      ),
    );
    final result = await _requestPhotoExchange(likeRequestId);
    if (isClosed) return;
    final LikesActionEvent event = result.fold((failure) {
      AppLogger.warning(
        'PHOTO-EXCHANGE — request transport failure id=$likeRequestId '
        'raw="${failure.message}"',
        tag: 'MATCHES',
      );
      return LikesActionEvent.photoExchangeRequestFailure;
    }, _requestEvent);
    final cleared = {...state.photoExchangeRequestInFlightLikeIds}
      ..remove(likeRequestId);
    emit(
      state.copyWith(
        photoExchangeRequestInFlightLikeIds: cleared,
        actionEvent: event,
        actionEventVersion: state.actionEventVersion + 1,
      ),
    );
    if (_shouldRefreshMatchesAfterRequest(event)) {
      await loadMatches();
    }
  }

  LikesActionEvent _requestEvent(PhotoExchangeRequestOutcome outcome) {
    return switch (outcome) {
      PhotoExchangeRequestSuccess() =>
        LikesActionEvent.photoExchangeRequestSuccess,
      PhotoExchangeRequestAlreadyPending() =>
        LikesActionEvent.photoExchangeRequestAlreadyPending,
      PhotoExchangeRequestLikeNotAccepted() =>
        LikesActionEvent.photoExchangeRequestLikeNotAccepted,
      PhotoExchangeRequestRequiresSubscription() =>
        LikesActionEvent.photoExchangeRequestRequiresSubscription,
      PhotoExchangeRequestLimitReached() =>
        LikesActionEvent.photoExchangeRequestLimitReached,
      PhotoExchangeRequestProfileUnderReview() =>
        LikesActionEvent.photoExchangeRequestUnderReview,
      PhotoExchangeRequestFailure() =>
        LikesActionEvent.photoExchangeRequestFailure,
    };
  }

  bool _shouldRefreshMatchesAfterRequest(LikesActionEvent event) {
    return switch (event) {
      LikesActionEvent.photoExchangeRequestSuccess ||
      LikesActionEvent.photoExchangeRequestAlreadyPending ||
      LikesActionEvent.photoExchangeRequestLikeNotAccepted => true,
      _ => false,
    };
  }

  // ── Photo exchange — responder (accept / reject) ───────────────────

  Future<void> acceptPhotoExchange(int requestId) async {
    if (state.isPhotoExchangeResponding(requestId)) return;
    emit(
      state.copyWith(
        photoExchangeAcceptInFlightRequestIds: {
          ...state.photoExchangeAcceptInFlightRequestIds,
          requestId,
        },
      ),
    );
    final result = await _acceptPhotoExchange(requestId);
    if (isClosed) return;
    final LikesActionEvent event = result.fold((failure) {
      AppLogger.warning(
        'PHOTO-EXCHANGE — accept transport failure requestId=$requestId '
        'raw="${failure.message}"',
        tag: 'MATCHES',
      );
      return LikesActionEvent.photoExchangeRespondFailure;
    }, (outcome) => _respondEvent(outcome, isAccept: true));
    final cleared = {...state.photoExchangeAcceptInFlightRequestIds}
      ..remove(requestId);
    emit(
      state.copyWith(
        photoExchangeAcceptInFlightRequestIds: cleared,
        actionEvent: event,
        actionEventVersion: state.actionEventVersion + 1,
      ),
    );
    if (_shouldRefreshMatchesAfterRespond(event)) {
      await loadMatches();
    }
  }

  Future<void> rejectPhotoExchange(int requestId) async {
    if (state.isPhotoExchangeResponding(requestId)) return;
    emit(
      state.copyWith(
        photoExchangeRejectInFlightRequestIds: {
          ...state.photoExchangeRejectInFlightRequestIds,
          requestId,
        },
      ),
    );
    final result = await _rejectPhotoExchange(requestId);
    if (isClosed) return;
    final LikesActionEvent event = result.fold((failure) {
      AppLogger.warning(
        'PHOTO-EXCHANGE — reject transport failure requestId=$requestId '
        'raw="${failure.message}"',
        tag: 'MATCHES',
      );
      return LikesActionEvent.photoExchangeRespondFailure;
    }, (outcome) => _respondEvent(outcome, isAccept: false));
    final cleared = {...state.photoExchangeRejectInFlightRequestIds}
      ..remove(requestId);
    emit(
      state.copyWith(
        photoExchangeRejectInFlightRequestIds: cleared,
        actionEvent: event,
        actionEventVersion: state.actionEventVersion + 1,
      ),
    );
    if (_shouldRefreshMatchesAfterRespond(event)) {
      await loadMatches();
    }
  }

  LikesActionEvent _respondEvent(
    PhotoExchangeRespondOutcome outcome, {
    required bool isAccept,
  }) {
    return switch (outcome) {
      PhotoExchangeRespondSuccess() =>
        isAccept
            ? LikesActionEvent.photoExchangeAcceptSuccess
            : LikesActionEvent.photoExchangeRejectSuccess,
      PhotoExchangeRespondNotFound() =>
        LikesActionEvent.photoExchangeRespondNotFound,
      PhotoExchangeRespondExpired() =>
        LikesActionEvent.photoExchangeRespondExpired,
      PhotoExchangeRespondFailure() =>
        LikesActionEvent.photoExchangeRespondFailure,
    };
  }

  bool _shouldRefreshMatchesAfterRespond(LikesActionEvent event) {
    return switch (event) {
      LikesActionEvent.photoExchangeAcceptSuccess ||
      LikesActionEvent.photoExchangeRejectSuccess ||
      LikesActionEvent.photoExchangeRespondNotFound ||
      LikesActionEvent.photoExchangeRespondExpired => true,
      _ => false,
    };
  }

  // ── Compatibility journey ──

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

  // ── Matchmaker inquiry / formal step — profile card + text message ──

  /// Stage-0 inquiry. The ticket requires both the viewed profile card and
  /// the predefined inquiry text to be present before the chat is opened.
  Future<void> sendInquiry(MatchCard card, String message) async {
    final id = card.likeRequestId;
    if (state.isInquirySending(id)) return;
    if (state.isInquirySent(id)) {
      _emitAction(LikesActionEvent.inquiryAlreadySent);
      return;
    }

    emit(
      state.copyWith(
        inquiryInFlightLikeIds: {...state.inquiryInFlightLikeIds, id},
      ),
    );
    final done = await _shareAndSend(card: card, message: message);
    if (isClosed) return;

    final cleared = {...state.inquiryInFlightLikeIds}..remove(id);
    emit(
      state.copyWith(
        inquiryInFlightLikeIds: cleared,
        inquirySentLikeIds: done
            ? {...state.inquirySentLikeIds, id}
            : state.inquirySentLikeIds,
        actionEvent: done
            ? LikesActionEvent.inquirySuccess
            : LikesActionEvent.inquiryFailure,
        actionEventVersion: state.actionEventVersion + 1,
      ),
    );
  }

  /// Stage 1/2 formal intent. Inquiry and formal-step guards are deliberately
  /// separate because a user may legitimately send both for the same match.
  Future<void> sendFormalStep(MatchCard card, String message) async {
    final id = card.likeRequestId;
    if (state.isFormalStepSending(id)) return;
    if (state.isFormalStepSent(id)) {
      _emitAction(LikesActionEvent.formalStepAlreadySent);
      return;
    }

    emit(
      state.copyWith(
        formalStepInFlightLikeIds: {...state.formalStepInFlightLikeIds, id},
      ),
    );
    final done = await _shareAndSend(card: card, message: message);
    if (isClosed) return;

    final cleared = {...state.formalStepInFlightLikeIds}..remove(id);
    emit(
      state.copyWith(
        formalStepInFlightLikeIds: cleared,
        formalStepSentLikeIds: done
            ? {...state.formalStepSentLikeIds, id}
            : state.formalStepSentLikeIds,
        actionEvent: done
            ? LikesActionEvent.formalStepSuccess
            : LikesActionEvent.formalStepFailure,
        actionEventVersion: state.actionEventVersion + 1,
      ),
    );
  }

  Future<bool> _shareAndSend({
    required MatchCard card,
    required String message,
  }) async {
    final conversationId = await _resolveConversationId(card);
    if (conversationId == null || isClosed) return false;

    final share = await _shareProfile(
      conversationId: conversationId,
      sharedUserId: card.otherUserId,
    );
    if (isClosed) return false;

    final canSendMessage = share.fold(
      (failure) {
        AppLogger.warning(
          'MATCHMAKER-SEND — share failed id=${card.likeRequestId} '
          'raw="${failure.message}"',
          tag: 'MATCHES',
        );
        return false;
      },
      (outcome) => switch (outcome) {
        // A rate limit here means the same profile was shared recently. The
        // accompanying text is still required and safe to attempt.
        ShareProfileSuccess() || ShareProfileRateLimited() => true,
        _ => false,
      },
    );
    if (!canSendMessage) {
      AppLogger.warning(
        'MATCHMAKER-SEND — profile share rejected id=${card.likeRequestId}',
        tag: 'MATCHES',
      );
      return false;
    }

    final send = await _sendText(
      conversationId: conversationId,
      content: message,
    );
    if (isClosed) return false;
    return send.fold((failure) {
      AppLogger.warning(
        'MATCHMAKER-SEND — text failed id=${card.likeRequestId} '
        'raw="${failure.message}"',
        tag: 'MATCHES',
      );
      return false;
    }, (outcome) => outcome is SendTextSuccess);
  }

  Future<int?> _resolveConversationId(MatchCard card) async {
    final embedded = int.tryParse(card.conversationId ?? '');
    if (embedded != null) return embedded;

    final result = await _getMyMatchmaker();
    if (isClosed) return null;
    return result.fold(
      (failure) {
        AppLogger.warning(
          'MATCHMAKER-SEND — resolve failed raw="${failure.message}"',
          tag: 'MATCHES',
        );
        return null;
      },
      (outcome) => switch (outcome) {
        MyMatchmakerAssigned(:final info) => info.conversationId,
        MyMatchmakerNotAssigned() || MyMatchmakerFailure() => null,
      },
    );
  }

  void _emitAction(LikesActionEvent event) {
    emit(
      state.copyWith(
        actionEvent: event,
        actionEventVersion: state.actionEventVersion + 1,
      ),
    );
  }
}
