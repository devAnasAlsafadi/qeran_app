import 'package:flutter/material.dart';
import 'package:qeran/core/theme/app_color.dart';
import 'package:qeran/core/utils/app_dimens.dart';

/// First-paint placeholder for the Full Profile Details screen when no
/// seed is available (e.g. chat-tap path). Plain coloured blocks —
/// avoids a third-party shimmer dependency. The hero block matches
/// the gallery height so the layout doesn't jump when the real image
/// lands.
class ProfileDetailsSkeleton extends StatelessWidget {
  const ProfileDetailsSkeleton({super.key});

  static const double _heroHeight = 360;

  @override
  Widget build(BuildContext context) {
    final block = AppColors.primary.withValues(alpha: 0.06);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(height: _heroHeight, color: block),
        const SizedBox(height: AppDimens.p16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.p20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Line(width: 180, color: block),
              const SizedBox(height: AppDimens.p12),
              _Line(width: double.infinity, color: block, height: 14),
              const SizedBox(height: AppDimens.p8),
              _Line(width: 240, color: block, height: 14),
              const SizedBox(height: AppDimens.p24),
              _Line(width: 140, color: block),
              const SizedBox(height: AppDimens.p12),
              Row(
                children: [
                  _Pill(color: block),
                  const SizedBox(width: AppDimens.p8),
                  _Pill(color: block),
                  const SizedBox(width: AppDimens.p8),
                  _Pill(color: block),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Line extends StatelessWidget {
  final double width;
  final double height;
  final Color color;
  const _Line({
    required this.width,
    required this.color,
    this.height = 18,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final Color color;
  const _Pill({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,
      height: 28,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}
