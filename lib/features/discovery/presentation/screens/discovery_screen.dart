import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';

import '../widgets/discovery_view.dart';

/// Standalone Discovery route. Thin Scaffold wrapper around
/// [DiscoveryView] — used when navigating to Discovery directly without
/// the Home shell. Inside `HomeScreen`, the embedded `DiscoveryView`
/// is used instead (with `showTopBar: false`).
class DiscoveryScreen extends StatelessWidget {
  const DiscoveryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: QeranSpacing.s16,
            vertical: QeranSpacing.s8,
          ),
          child: const DiscoveryView(),
        ),
      ),
    );
  }
}
