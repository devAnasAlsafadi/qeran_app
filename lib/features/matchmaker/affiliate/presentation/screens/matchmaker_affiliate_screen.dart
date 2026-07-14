import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/widgets/qeran_app_bar.dart';
import 'package:qeran/core/design_system/widgets/qeran_loader.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

/// Matchmaker affiliate & commissions dashboard (pushed from the account
/// screen). Caller is resolved from the JWT — no arguments.
///
/// Stub for now: the real body (referral code + earnings tiles + commissions
/// ledger, backed by `/affiliate/summary` and `/affiliate/commissions`) lands
/// in later sub-steps. Kept minimal so the route resolves cleanly.
class MatchmakerAffiliateScreen extends StatelessWidget {
  const MatchmakerAffiliateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QeranColors.creamCanvas,
      appBar: QeranAppBar(
        title: LocaleKeys.matchmaker_affiliate_row_title.t(context),
      ),
      body: const Center(child: QeranLoader()),
    );
  }
}
