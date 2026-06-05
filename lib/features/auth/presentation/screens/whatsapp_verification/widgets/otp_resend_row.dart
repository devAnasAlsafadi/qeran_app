import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

class OtpResendRow extends StatefulWidget {
  final VoidCallback onResend;
  final bool isLoading;
  final int cooldownSeconds;

  const OtpResendRow({
    super.key,
    required this.onResend,
    required this.isLoading,
    this.cooldownSeconds = 60,
  });

  @override
  State<OtpResendRow> createState() => _OtpResendRowState();
}

class _OtpResendRowState extends State<OtpResendRow> {
  int _secondsRemaining = 0;
  Timer? _timer;

  bool get _canResend => _secondsRemaining == 0 && !widget.isLoading;

  void _startTimer() {
    setState(() => _secondsRemaining = widget.cooldownSeconds);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
      }
    });
  }

  void _handleResend() {
    if (_canResend) {
      widget.onResend();
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: _canResend ? _handleResend : null,
          child: Text(
            _secondsRemaining > 0
                ? LocaleKeys.auth_otp_resend_timer.tr(
                    namedArgs: {'seconds': _secondsRemaining.toString()},
                  )
                : LocaleKeys.auth_otp_resend.t(context),
            style: QeranTypography.body.copyWith(
              color: _canResend
                  ? QeranColors.gold
                  : QeranColors.inkMuted.withValues(alpha: 0.5),
            ),
          ),
        ),
        QeranSpacing.hs4,
        Text(
          LocaleKeys.auth_otp_no_code.t(context),
          style: QeranTypography.body.copyWith(
            color: QeranColors.inkMuted,
          ),
        ),
      ],
    );
  }
}
