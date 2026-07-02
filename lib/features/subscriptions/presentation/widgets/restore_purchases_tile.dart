import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/config/revenuecat_config.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/design_system/widgets/qeran_card.dart';
import 'package:qeran/core/design_system/widgets/qeran_loader.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/enum/snakebar_tybe.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/utils/app_snackbar.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../blocs/purchase/package_purchase_cubit.dart';
import '../blocs/purchase/package_purchase_state.dart';

/// "Restore purchases" tile for the اشتراكي screen. Enabled on **both**
/// platforms (restore triggers no payment — it only re-syncs entitlements), so
/// it stays available even under the iOS purchase lockdown (Q-B). Owns its own
/// [PackagePurchaseCubit] since the details screen isn't in the paywall tree.
class RestorePurchasesTile extends StatelessWidget {
  const RestorePurchasesTile({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PackagePurchaseCubit>(
      create: (_) => sl<PackagePurchaseCubit>(),
      child: BlocConsumer<PackagePurchaseCubit, PackagePurchaseState>(
        listener: _onState,
        builder: (context, state) {
          final busy = state is PackagePurchaseInProgress;
          return _Tile(
            busy: busy,
            onTap: busy
                ? null
                : () =>
                    context.read<PackagePurchaseCubit>().restorePurchases(),
          );
        },
      ),
    );
  }

  void _onState(BuildContext context, PackagePurchaseState state) {
    switch (state) {
      case PackagePurchaseSuccess():
        // Right is returned even with nothing to restore — distinguish by the
        // premium entitlement (UI-level, no cubit change).
        final restored = state.customerInfo.entitlements.active
            .containsKey(RevenueCatConfig.premiumEntitlementId);
        AppSnackBar.show(
          context,
          message: (restored
                  ? LocaleKeys.subscriptions_restore_success
                  : LocaleKeys.subscriptions_restore_no_purchases)
              .t(context),
          type: restored ? SnackBarType.success : SnackBarType.notice,
        );
      case PackagePurchaseFailure(:final userMessage):
        AppSnackBar.show(
          context,
          message: userMessage.t(context),
          type: SnackBarType.error,
        );
      // Cancelled → silent; InProgress / Idle / CodeValidation* → not applicable.
      default:
        break;
    }
  }
}

class _Tile extends StatelessWidget {
  final bool busy;
  final VoidCallback? onTap;

  const _Tile({required this.busy, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return QeranCard(
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        borderRadius: QeranRadii.cardR,
        child: InkWell(
          onTap: onTap,
          borderRadius: QeranRadii.cardR,
          splashColor: QeranColors.creamSurface,
          highlightColor: QeranColors.creamSurface.withValues(alpha: 0.5),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: QeranColors.creamSurface,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.restore_rounded,
                      size: 20, color: QeranColors.wine),
                ),
                QeranSpacing.hs12,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        LocaleKeys.subscriptions_restore_purchases.t(context),
                        style: QeranTypography.body
                            .copyWith(color: QeranColors.wine),
                      ),
                      QeranSpacing.vs4,
                      Text(
                        LocaleKeys.subscriptions_restore_purchases_subtitle
                            .t(context),
                        style: QeranTypography.caption
                            .copyWith(color: QeranColors.inkMuted),
                      ),
                    ],
                  ),
                ),
                QeranSpacing.hs12,
                busy
                    ? QeranLoader.inline(color: QeranColors.wine)
                    : Icon(
                        isRtl
                            ? Icons.chevron_left_rounded
                            : Icons.chevron_right_rounded,
                        size: 22,
                        color: QeranColors.wine20,
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
