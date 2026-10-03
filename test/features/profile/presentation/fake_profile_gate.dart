import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/profile/domain/entities/profile_status.dart';
import 'package:qeran/features/profile/presentation/blocs/profile_gate/profile_gate_cubit.dart';
import 'package:qeran/features/profile/presentation/blocs/profile_gate/profile_gate_state.dart';

/// The profile gate frozen at [status] (null: not known yet).
class FakeGate extends Fake implements ProfileGateCubit {
  FakeGate([this._status]);

  final ProfileStatus? _status;

  @override
  ProfileGateState get state => _status == null
      ? const ProfileGateInitial()
      : ProfileGateResolved(_status);

  @override
  Stream<ProfileGateState> get stream => const Stream.empty();

  @override
  ProfileStatus? get status => _status;

  @override
  bool get isGated => switch (_status) {
    ProfileStatus.pendingReview ||
    ProfileStatus.hidden ||
    ProfileStatus.rejected => true,
    _ => false,
  };
}
