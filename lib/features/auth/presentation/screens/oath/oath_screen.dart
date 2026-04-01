import 'package:flutter/material.dart';
import 'package:qeran/core/constants/storage_keys.dart';
import 'package:qeran/core/datasources/shared_pref_service.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/routes/navigation_manager.dart';
import 'package:qeran/core/routes/route_name.dart';
import 'package:qeran/core/theme/app_color.dart';
import 'package:qeran/core/theme/app_text_style.dart';
import 'package:qeran/core/utils/app_assets.dart';
import 'package:qeran/core/utils/app_dimens.dart';
import 'package:qeran/core/widgets/app_button.dart';

class OathScreen extends StatefulWidget {
  const OathScreen({super.key});

  @override
  State<OathScreen> createState() => _OathScreenState();
}

class _OathScreenState extends State<OathScreen> {
  bool _isChecked = false;
  final SharedPrefService _sharedPrefs = sl<SharedPrefService>();

  void _onSwear() async {
    if (!_isChecked) return;
    await _sharedPrefs.save(StorageKeys.signedOath, true);
    if (!mounted) return;
    NavigationManager.navigateAndReplace(context, RouteNames.photoUploadScreen);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.p24,
            vertical: AppDimens.p16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 1),
              
              // ── Logo ──
              Center(
                child: Image.asset(AppAssets.logo, width: 140),
              ),
              const SizedBox(height: AppDimens.p32),

              // ── Title ──
              Center(
                child: Text(
                  'القسم',
                  style: AppTextStyles.displayLarge.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: AppDimens.p8),
              Center(
                child: Container(
                  height: 2,
                  width: 60,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: AppDimens.p32),

              // ── Oath Text ──
              Container(
                padding: const EdgeInsets.all(AppDimens.p24),
                decoration: BoxDecoration(
                  color: AppColors.fieldBackground,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: Column(
                  children: [
                    Text(
                      'بسم الله الرحمن الرحيم',
                      style: AppTextStyles.headlineMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppDimens.p16),
                    Text(
                      'أتعهد أمام الله أن أستخدم هذا التطبيق\n'
                      'بنية صادقة للزواج فقط\n'
                      'وأن ألتزم بالصدق والأخلاق في جميع تعاملاتي.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.textPrimary,
                        height: 1.8,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimens.p32),

              // ── Checkbox Row ──
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Checkbox(
                    value: _isChecked,
                    activeColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    onChanged: (val) {
                      setState(() {
                         _isChecked = val ?? false;
                      });
                    },
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                           _isChecked = !_isChecked;
                        });
                      },
                      child: Text(
                        'أوافق على هذا القسم وأتحمل المسؤولية أمام الله',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              const Spacer(flex: 2),

              // ── Footer Text ──
              Text(
                'سيتم تسجيل موافقتك على هذا التعهد في حسابك',
                textAlign: TextAlign.center,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppDimens.p16),

              // ── Oath CTA Button ──
              CustomButton(
                text: 'أقسم',
                backgroundColor: _isChecked ? AppColors.primary : AppColors.grey,
                onPressed: _isChecked ? _onSwear : null,
              ),
              const SizedBox(height: AppDimens.p16),
            ],
          ),
        ),
      ),
    );
  }
}
