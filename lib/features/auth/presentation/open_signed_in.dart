import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:qeran/core/routes/navigation_manager.dart';
import 'package:qeran/core/routes/route_name.dart';
import 'package:qeran/core/utils/keyboard_dismissal.dart';

import '../domain/entities/user_entity.dart';

/// Where a signed-in account goes: the one way out of sign-in, for email,
/// Google, Apple and the WhatsApp code, in both roles.
///
/// The keyboard is told to close first. On an iPhone a field left focused
/// under Google's sheet got the keyboard back when the sheet closed, and the
/// screens were then replaced under it: it stayed up over home.
///
/// [phoneVerified] is for the WhatsApp code: its answer verifies the phone
/// whatever the answer's own flag says.
void openSignedIn(
  BuildContext context,
  UserEntity user, {
  bool phoneVerified = false,
}) {
  unawaited(dismissKeyboard());
  final next = signedInRoute(user, phoneVerified: phoneVerified);
  if (next.onTop) {
    NavigationManager.navigateTo(context, next.route);
  } else {
    NavigationManager.pushNamedAndRemoveUntil(context, next.route);
  }
}

/// The role first: a matchmaker has none of a member's onboarding steps (the
/// server lets her skip phone verification). A member without a verified
/// phone verifies it on top of the sign-in screen, so its back returns there;
/// one who hasn't answered the questions starts them; everyone else is home.
({String route, bool onTop}) signedInRoute(
  UserEntity user, {
  bool phoneVerified = false,
}) {
  if (user.role?.toLowerCase() == 'moderator') {
    return (route: RouteNames.matchmakerHome, onTop: false);
  }
  if (!phoneVerified && user.isPhoneVerified != true) {
    return (route: RouteNames.whatsappInput, onTop: true);
  }
  if (user.hasAnsweredQuestions != true) {
    return (route: RouteNames.genderSelectionScreen, onTop: false);
  }
  return (route: RouteNames.homeScreen, onTop: false);
}
