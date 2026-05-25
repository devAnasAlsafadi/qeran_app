import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:qeran/core/theme/app_color.dart';
import 'package:qeran/core/theme/app_text_style.dart';
import 'package:qeran/core/utils/app_dimens.dart';
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
            style: AppTextStyles.bodyMedium.copyWith(
              color: _canResend
                  ? AppColors.primaryLight
                  : AppColors.textSecondary.withValues(alpha: 0.5),
            ),
          ),
        ),
        const SizedBox(width: AppDimens.p4),
        Text(
          LocaleKeys.auth_otp_no_code.t(context),
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
