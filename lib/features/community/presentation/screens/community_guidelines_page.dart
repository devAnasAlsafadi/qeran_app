import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../core/design_system/widgets/qeran_app_bar.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/extensions/localization_extension.dart';
import '../../../../generated/locale_keys.g.dart';
import '../blocs/guidelines/community_guidelines_cubit.dart';
import 'community_guidelines_screen.dart';

/// Opens the guidelines step over [context] (D7, F5): true once the member
/// has agreed, false for «ليس الآن» or going back (F7). A
/// `MaterialPageRoute`, so iOS keeps its edge-swipe back.
Future<bool> openCommunityGuidelines(BuildContext context) async {
  final agreed = await Navigator.of(context).push<bool>(
    MaterialPageRoute(builder: (_) => const CommunityGuidelinesPage()),
  );
  return agreed ?? false;
}

/// The pushed guidelines step: «إرشادات المجتمع» on paper, over the
/// server's text.
class CommunityGuidelinesPage extends StatelessWidget {
  const CommunityGuidelinesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CommunityGuidelinesCubit>(
      create: (_) => sl<CommunityGuidelinesCubit>()..load(),
      child: Scaffold(
        backgroundColor: QeranColors.creamCanvas,
        appBar: QeranAppBar(
          title: LocaleKeys.community_guidelines_title.t(context),
          background: QeranColors.paper,
        ),
        body: const CommunityGuidelinesScreen(),
      ),
    );
  }
}
