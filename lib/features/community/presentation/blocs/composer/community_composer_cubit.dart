import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/state/safe_emit.dart';
import '../../../domain/entities/comment_submit_outcome.dart';
import '../../../domain/entities/community_comment.dart';
import '../../../domain/usecases/get_community_config_usecase.dart';
import 'community_composer_state.dart';
import 'community_gate.dart';

/// Sends [text] — a reply under [parentId], or a comment — and answers with
/// what came of it (the comments cubit's `send`).
typedef CommentSend =
    Future<CommentSubmitOutcome?> Function(String text, {int? parentId});

/// Sends the failed [localId] again (the comments cubit's `retry`).
typedef CommentRetry = Future<CommentSubmitOutcome?> Function(int localId);

/// The step the member owes before writing, as the app last read it.
typedef OwedGate = CommunityGate? Function();

/// The comment field (D1–D10): comment or reply, the server's limit, and
/// what happens to the text when a send doesn't go through — back in the
/// field, with the filter's banner (D8), the rate limit's rest (D9), a
/// gate to run first (S5), or the answered comment gone (S9). Sending
/// itself, and the rows, are the comments cubit's.
///
/// A member who owes a step — a real name, the guidelines — takes it before
/// the field opens: tapping the field or Reply runs the steps one at a time,
/// then the field takes the focus (F6); a step left undone leaves it (F7).
class CommunityComposerCubit extends Cubit<CommunityComposerState>
    with SafeEmit<CommunityComposerState> {
  CommunityComposerCubit({
    required GetCommunityConfigUseCase getConfig,
    required CommentSend send,
    required CommentRetry retry,
    OwedGate owed = _nothingOwed,
    this.defaultCooldown = const Duration(seconds: 30),
  }) : _getConfig = getConfig,
       _send = send,
       _retry = retry,
       _owed = owed,
       super(CommunityComposerState(owes: owed()));

  final GetCommunityConfigUseCase _getConfig;
  final CommentSend _send;
  final CommentRetry _retry;
  final OwedGate _owed;

  /// The comment whose Reply was tapped while a step was owed.
  CommunityComment? _answering;

  static CommunityGate? _nothingOwed() => null;

  /// The rest after a rate limit that didn't say how long (a bare 429).
  final Duration defaultCooldown;
  Timer? _cooldown;

  /// The limit, once per app session (S15); without it the server checks.
  Future<void> loadConfig() async {
    final result = await _getConfig();
    result.fold(
      (_) {},
      (config) => emit(state.copyWith(maxLength: config.commentMaxLength)),
    );
  }

  /// Reply to [comment]: the strip shows, the field takes the focus (D2) —
  /// once the steps owed are taken.
  void replyTo(CommunityComment comment) {
    _answering = comment;
    _askNext();
  }

  /// The waiting field was tapped: the steps owed come first.
  void startWriting() => _askNext();

  /// A step came back. Taken ([done]): the next one, or the field (F6) —
  /// a step the app still sees as owed isn't asked twice; the server
  /// checks on send (S5). Left: nothing more (F7).
  void stepClosed({required bool done}) {
    if (!done) {
      _answering = null;
      return;
    }
    final closed = state.owes;
    final next = _owed();
    emit(state.copyWith(owes: () => next == closed ? null : next));
    _askNext();
  }

  /// The next step owed, or — none left — the field, answering the comment
  /// whose Reply was tapped.
  void _askNext() {
    final gate = state.owes;
    if (gate != null) return emit(state.withEvent(openingOf(gate)));
    final answering = _answering;
    _answering = null;
    emit(
      state
          .copyWith(
            replyTo: answering == null ? null : () => answering,
            filtered: false,
          )
          .withEvent(CommunityComposerEvent.focus),
    );
  }

  void cancelReply() => emit(state.copyWith(replyTo: () => null));

  /// Sends [text]; the field has already cleared (D5). Nothing goes while
  /// it's empty, too long, or resting after a rate limit.
  Future<void> submit(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.coolingDown || state.tooLong(trimmed)) {
      return;
    }
    final parent = state.replyTo;
    emit(state.copyWith(replyTo: () => null, filtered: false));
    final outcome = await _send(trimmed, parentId: parent?.id);
    _settle(outcome, trimmed, parent);
  }

  /// A failed row's retry (D7): the same [text], answering [parent].
  Future<void> retry(
    int localId,
    String text, {
    CommunityComment? parent,
  }) async => _settle(await _retry(localId), text, parent);

  void _settle(
    CommentSubmitOutcome? outcome,
    String text,
    CommunityComment? parent,
  ) {
    final event = switch (outcome) {
      CommentFiltered() => CommunityComposerEvent.filtered,
      CommentRateLimited(:final retryAfter) => _restAfter(retryAfter),
      CommentNameRequired() => CommunityComposerEvent.openNameGate,
      CommentGuidelinesRequired() => CommunityComposerEvent.openGuidelines,
      CommentNotApproved() => CommunityComposerEvent.notApproved,
      CommentParentGone() => CommunityComposerEvent.contentGone,
      null || CommentPosted() || CommentPostGone() => null,
    };
    if (event == null) return;
    final answering = outcome is CommentParentGone ? null : parent;
    emit(
      state
          .copyWith(
            replyTo: () => answering,
            filtered: outcome is CommentFiltered,
            restore: () => text,
            owes: () => _owedAfter(outcome),
          )
          .withEvent(event),
    );
  }

  /// The server's word on a step beats the app's (S5).
  CommunityGate? _owedAfter(CommentSubmitOutcome? outcome) => switch (outcome) {
    CommentNameRequired() => CommunityGate.name,
    CommentGuidelinesRequired() => CommunityGate.guidelines,
    _ => state.owes,
  };

  CommunityComposerEvent _restAfter(Duration? retryAfter) {
    final wait = retryAfter ?? defaultCooldown;
    _cooldown?.cancel();
    _cooldown = Timer(
      wait,
      () => emit(state.copyWith(cooldownUntil: () => null)),
    );
    emit(state.copyWith(cooldownUntil: () => DateTime.now().add(wait)));
    return CommunityComposerEvent.rateLimited;
  }

  @override
  Future<void> close() {
    _cooldown?.cancel();
    return super.close();
  }
}
