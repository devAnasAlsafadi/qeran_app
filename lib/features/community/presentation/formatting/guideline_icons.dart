import 'package:flutter/material.dart';

import '../../../../core/app_logger.dart';

/// A guidelines section's icon (W2). The server names a Material Symbols
/// icon, and the client can change it from the admin panel, so a name the
/// app doesn't know gets a neutral icon instead of none — and is logged.
IconData guidelineIcon(String name) {
  final icon = _icons[name.trim()];
  if (icon != null) return icon;
  AppLogger.warning(
    'Guidelines icon "$name" is not mapped, using the fallback',
    tag: 'COMMUNITY',
  );
  return guidelineIconFallback;
}

/// For a name the app doesn't know.
const IconData guidelineIconFallback = Icons.info_outline_rounded;

/// The outlined forms, as the boards draw Material Symbols (unfilled).
const Map<String, IconData> _icons = {
  // The server's, in both texts (contract §4.1).
  'block': Icons.block_rounded,
  'phone_disabled': Icons.phone_disabled_outlined,
  'lock': Icons.lock_outline_rounded,
  'campaign': Icons.campaign_outlined,
  'flag': Icons.flag_outlined,
  'lightbulb': Icons.lightbulb_outline_rounded,
  'shield': Icons.shield_outlined,
  // The boards', should the client pick them.
  'handshake': Icons.handshake_outlined,
  'gpp_bad': Icons.gpp_bad_outlined,
  'person_off': Icons.person_off_outlined,
};
