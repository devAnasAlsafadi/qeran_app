import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/api/end_points.dart';
import 'package:qeran/features/auth/domain/entities/user_entity.dart';
import 'package:qeran/features/auth/presentation/blocs/user_session/user_session_cubit.dart';
import 'package:qeran/features/auth/presentation/blocs/user_session/user_session_state.dart';

const fakeSessionToken = 'jwt-123';
const fakeSessionBearer = {'Authorization': 'Bearer $fakeSessionToken'};

/// A profile image on our own server.
final ourImageUrl = EndPoints.absoluteUrl('/api/users/profile-images/img-1');

/// An image anywhere else — here a look-alike of our own host.
final foreignImageUrl =
    'https://${Uri.parse(EndPoints.baseUrl).host}.evil.example/api/users/profile-images/img-1';

/// A session cubit frozen in [state]: signed in with [fakeSessionToken] by
/// default.
class FakeSession extends Fake implements UserSessionCubit {
  FakeSession([UserSessionState? state])
    : state =
          state ??
          const UserSessionAuthenticated(
            UserEntity(
              id: 'u-1',
              name: 'Huda',
              email: 'huda@test.com',
              token: fakeSessionToken,
            ),
          );

  @override
  final UserSessionState state;

  @override
  Stream<UserSessionState> get stream => const Stream.empty();
}

/// [child] under a signed-in [FakeSession].
Widget withSession(Widget child, {UserSessionState? state}) =>
    BlocProvider<UserSessionCubit>.value(
      value: FakeSession(state),
      child: child,
    );
