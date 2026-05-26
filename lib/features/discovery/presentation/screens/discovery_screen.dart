import 'package:flutter/material.dart';
import 'package:qeran/core/utils/app_dimens.dart';

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
            horizontal: AppDimens.p16,
            vertical: AppDimens.p8,
          ),
          child: const DiscoveryView(),
        ),
      ),
    );
  }
}
