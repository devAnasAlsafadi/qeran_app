import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../core/design_system/widgets/qeran_app_bar.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/extensions/localization_extension.dart';
import '../../../../generated/locale_keys.g.dart';
import '../../../profile/presentation/blocs/name/name_cubit.dart';
import 'community_name_gate_screen.dart';

/// Opens the name step over [context] (D17, F1–F3): true once the member
/// has a real display name, false when they went back without one. A
/// `MaterialPageRoute`, so iOS keeps its edge-swipe back.
Future<bool> openCommunityNameGate(BuildContext context) async {
  final named = await Navigator.of(context).push<bool>(
    MaterialPageRoute(builder: (_) => const CommunityNameGatePage()),
  );
  return named ?? false;
}

/// The pushed name step: «اسمك في المجتمع» on paper, over the member's
/// profile read fresh.
class CommunityNameGatePage extends StatelessWidget {
  const CommunityNameGatePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<NameCubit>(
      create: (_) => sl<NameCubit>()..load(),
      child: Scaffold(
        backgroundColor: QeranColors.creamCanvas,
        appBar: QeranAppBar(
          title: LocaleKeys.community_name_gate_header.t(context),
          background: QeranColors.paper,
        ),
        body: const SafeArea(child: CommunityNameGateScreen()),
      ),
    );
  }
}
