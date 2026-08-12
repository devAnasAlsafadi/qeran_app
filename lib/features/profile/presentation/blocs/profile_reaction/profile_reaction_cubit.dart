import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/app_logger.dart';
import 'package:qeran/core/state/safe_emit.dart';
import 'package:qeran/features/discovery/domain/entities/like_outcome.dart';
import 'package:qeran/features/discovery/domain/usecases/like_profile_usecase.dart';
import 'package:qeran/features/discovery/domain/usecases/pass_profile_usecase.dart';

import '../profile_gate/profile_gate_cubit.dart';
import 'profile_reaction_state.dart';

/// Like/pass actions for a profile opened from a shared chat card.
///
/// This intentionally reuses the discovery domain use-cases and their typed
/// outcomes; chat is only another entry point to the same server actions.
class ProfileReactionCubit extends Cubit<ProfileReactionState>
    with SafeEmit<ProfileReactionState> {
  final LikeProfileUseCase _likeProfile;
  final PassProfileUseCase _passProfile;
  final ProfileGateCubit _profileGate;
  final Future<void> Function() _onLikeSuccess;

  ProfileReactionCubit({
    required LikeProfileUseCase likeProfile,
    required PassProfileUseCase passProfile,
    required ProfileGateCubit profileGate,
    Future<void> Function()? onLikeSuccess,
  }) : _likeProfile = likeProfile,
       _passProfile = passProfile,
       _profileGate = profileGate,
       _onLikeSuccess = onLikeSuccess ?? _noOp,
       super(const ProfileReactionState());

  static Future<void> _noOp() async {}

  Future<void> like(String userId) async {
    if (state.isBusy) return;
    if (_profileGate.isGated) {
      _emitEvent(ProfileReactionEvent.underReview);
      return;
    }
    emit(
      ProfileReactionState(
        inFlight: ProfileReactionAction.like,
        eventVersion: state.eventVersion,
      ),
    );
    final result = await _likeProfile(userId);
    if (isClosed) return;
    result.fold(
      (failure) {
        AppLogger.warning(
          'PROFILE-REACTION — like failed raw="${failure.message}"',
          tag: 'PROFILE',
        );
        _emitEvent(ProfileReactionEvent.failure);
      },
      (outcome) {
        switch (outcome) {
          case LikeAccepted():
            unawaited(_onLikeSuccess());
            _emitEvent(ProfileReactionEvent.likeSuccess);
          case LikePaywall():
            _emitEvent(ProfileReactionEvent.paywall);
          case LikeAlreadyPending():
            _emitEvent(ProfileReactionEvent.alreadyPending);
          case LikeGenderMismatch():
            _emitEvent(ProfileReactionEvent.genderMismatch);
          case LikeUserUnavailable():
            _emitEvent(ProfileReactionEvent.userUnavailable);
          case LikeUnderReview():
            _emitEvent(ProfileReactionEvent.underReview);
        }
      },
    );
  }

  Future<void> pass(String userId) async {
    if (state.isBusy) return;
    emit(
      ProfileReactionState(
        inFlight: ProfileReactionAction.pass,
        eventVersion: state.eventVersion,
      ),
    );
    final result = await _passProfile(userId);
    if (isClosed) return;
    result.fold((failure) {
      AppLogger.warning(
        'PROFILE-REACTION — pass failed raw="${failure.message}"',
        tag: 'PROFILE',
      );
      _emitEvent(ProfileReactionEvent.failure);
    }, (_) => _emitEvent(ProfileReactionEvent.passSuccess));
  }

  void _emitEvent(ProfileReactionEvent event) {
    emit(
      ProfileReactionState(event: event, eventVersion: state.eventVersion + 1),
    );
  }
}
