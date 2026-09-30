import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qeran/core/design_system/theme/qeran_system_bars.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/widgets/connectivity_banner_host.dart';

import 'chat_entry_screen.dart';

/// Opens the member's chat with their matchmaker as a pushed screen.
///
/// A `MaterialPageRoute`, so iOS keeps its edge-swipe back.
Future<void> openMatchmakerChat(BuildContext context) => Navigator.of(
  context,
).push(MaterialPageRoute<void>(builder: (_) => const MyMatchmakerChatPage()));

/// The pushed chat page. No outer safe area: the paper header runs under the
/// status bar (dark icons over it), and the composer takes the bottom inset
/// itself so it sits on the safe area — or directly on the keyboard. Offline,
/// the banner comes out from under the header instead of covering it.
class MyMatchmakerChatPage extends StatelessWidget {
  const MyMatchmakerChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: QeranSystemBars.darkIcons,
      child: Scaffold(
        backgroundColor: QeranColors.creamCanvas,
        body: AttachedConnectivityBanner(
          child: ChatEntryScreen(onBack: () => Navigator.of(context).pop()),
        ),
      ),
    );
  }
}
