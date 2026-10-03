import 'package:flutter/material.dart';

import '../../domain/entities/profile_status.dart';

/// The icon that says why a member can't take part yet, wherever the app
/// says it (Likes, the plans, Community): one icon per status, so the same
/// message looks the same on every screen.
IconData profileGateIcon(ProfileStatus? status) => switch (status) {
  ProfileStatus.hidden => Icons.visibility_off_rounded,
  ProfileStatus.rejected => Icons.error_outline_rounded,
  _ => Icons.hourglass_top_rounded,
};
