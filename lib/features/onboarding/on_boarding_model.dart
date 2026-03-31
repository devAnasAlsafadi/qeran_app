import '../../core/utils/app_assets.dart';

class OnboardingModel {
  final String title;
  final String description;
  final String image;

  OnboardingModel({required this.title, required this.description, required this.image});
}


List<OnboardingModel> onboardingData = [
  OnboardingModel(
    title: "ابحث عن شريك حياتك",
    description: "تطبيق قرآن يوفر لك بيئة آمنة وجادة للبحث عن نصفك الآخر وفق الضوابط الشرعية.",
    image: AppAssets.onboarding1,
  ),
  OnboardingModel(
    title: "توافق دقيق",
    description: "نظامنا الذكي يساعدك في العثور على من يناسبك بناءً على إجاباتك واهتماماتك.",
    image: AppAssets.onboarding2,
  ),
  OnboardingModel(
    title: "تواصل بثقة",
    description: "تواصل مع الآخرين من خلال رسائل آمنة ومراقبة لضمان تجربة إيجابية.",
    image: AppAssets.onboarding3,
  ),
];