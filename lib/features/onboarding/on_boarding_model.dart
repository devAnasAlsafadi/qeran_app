import 'package:qeran/generated/locale_keys.g.dart';

import '../../core/utils/app_assets.dart';

class OnboardingModel {
  final String title;
  final String description;
  final String image;

  OnboardingModel({
    required this.title,
    required this.description,
    required this.image,
  });
}

List<OnboardingModel> onboardingData = [
  OnboardingModel(
    title: LocaleKeys.onboarding_page1_title,
    description: LocaleKeys.onboarding_page1_description,
    image: AppAssets.onboarding1,
  ),
  OnboardingModel(
    title: LocaleKeys.onboarding_page2_title,
    description: LocaleKeys.onboarding_page2_description,
    image: AppAssets.onboarding2,
  ),
  OnboardingModel(
    title: LocaleKeys.onboarding_page3_title,
    description: LocaleKeys.onboarding_page3_description,
    image: AppAssets.onboarding3,
  ),
];
