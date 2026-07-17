import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_shadows.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

/// Live "resets in …" pill for the daily-view limit. Recomputes every 30s from
/// [resetAt] (next UTC midnight). Arabic uses dual/plural forms
/// (ساعة/ساعتين/ساعات · دقيقة/دقيقتين/دقائق); English a compact `h`/`m`. Shows
/// "resetting now" once the instant passes.
class ResetCountdown extends StatefulWidget {
  final DateTime resetAt;
  const ResetCountdown({super.key, required this.resetAt});

  @override
  State<ResetCountdown> createState() => _ResetCountdownState();
}

class _ResetCountdownState extends State<ResetCountdown> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: QeranSpacing.s16,
        vertical: QeranSpacing.s8,
      ),
      decoration: const BoxDecoration(
        color: QeranColors.creamSurface,
        borderRadius: QeranRadii.pill,
        boxShadow: QeranShadows.e1,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.schedule_rounded,
            size: 18,
            color: QeranColors.goldDeep,
          ),
          QeranSpacing.hs8,
          Text(
            _format(context),
            style: QeranTypography.bodySm.copyWith(
              color: QeranColors.wine,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  String _format(BuildContext context) {
    final ms = widget.resetAt.difference(DateTime.now()).inMilliseconds;
    if (ms <= 0) {
      return LocaleKeys.discovery_daily_limit_reset_now.t(context);
    }
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final prefix = LocaleKeys.discovery_daily_limit_reset_prefix.t(context);
    final totalMin = math.max(1, (ms / 60000).round());

    if (totalMin >= 60) {
      return _unit(
        context, isArabic, prefix, (totalMin / 60).round(),
        singular: LocaleKeys.discovery_daily_limit_hour_singular,
        dual: LocaleKeys.discovery_daily_limit_hour_dual,
        plural: LocaleKeys.discovery_daily_limit_hour_plural,
      );
    }
    return _unit(
      context, isArabic, prefix, totalMin,
      singular: LocaleKeys.discovery_daily_limit_minute_singular,
      dual: LocaleKeys.discovery_daily_limit_minute_dual,
      plural: LocaleKeys.discovery_daily_limit_minute_plural,
    );
  }

  /// Assembles "prefix [n] unit". English is compact (`Resets in 5h`); Arabic
  /// selects the dual/plural form and omits the digit for 1 and 2.
  String _unit(
    BuildContext context,
    bool isArabic,
    String prefix,
    int n, {
    required String singular,
    required String dual,
    required String plural,
  }) {
    if (!isArabic) return '$prefix $n${singular.t(context)}';
    if (n == 1) return '$prefix ${singular.t(context)}';
    if (n == 2) return '$prefix ${dual.t(context)}';
    if (n <= 10) return '$prefix $n ${plural.t(context)}';
    return '$prefix $n ${singular.t(context)}';
  }
}
