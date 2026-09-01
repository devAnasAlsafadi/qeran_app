import 'package:flutter/foundation.dart';

/// Lets one screen ask [AppLifecyclePrivacyShield] to stand down while it is on
/// screen.
///
/// The shield lives ABOVE the Navigator so it can cover every route, which also
/// means a route cannot reach it through the widget tree — the signal has to be
/// a shared object rather than an inherited one.
///
/// ⚠️ Opt-in, and deliberately hard to reach by accident: the default is "not
/// suppressed", and nothing suppresses unless it says so and undoes it on
/// dispose. The shield exists to keep photos, chats and profile data out of the
/// app-switcher snapshot — suppressing it on a screen that shows any of those
/// would defeat the whole point.
///
/// The splash is the one legitimate caller. It renders a logo on a flat canvas
/// and nothing else, so there is nothing there to protect; and the fill it was
/// receiving is the same wine as the splash canvas, so the animation simply
/// vanished with the screen still looking correct.
final ValueNotifier<bool> privacyShieldSuppressed = ValueNotifier<bool>(false);
