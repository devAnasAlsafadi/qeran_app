import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../../core/utils/app_dimens.dart';

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
            _secondsRemaining > 0 ? 'إعادة إرسال ($_secondsRemaining)' : 'إعادة إرسال',
            style: AppTextStyles.bodyMedium.copyWith(
              color: _canResend ? AppColors.primaryLight : AppColors.textSecondary.withValues(alpha: 0.5),
            ),
          ),
        ),
        const SizedBox(width: AppDimens.p4),
        Text(
          'لم تحصل على الكود ؟',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
