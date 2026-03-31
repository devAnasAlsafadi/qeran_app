part of 'onboarding_cubit.dart';

sealed class OnboardingState extends Equatable {
  final int currentPage;

  const OnboardingState({this.currentPage = 0});

  bool get isFirstPage => currentPage == 0;
  bool get isLastPage => currentPage == onboardingData.length - 1;

  @override
  List<Object?> get props => [currentPage];
}

final class OnboardingIdle extends OnboardingState {
  const OnboardingIdle({super.currentPage});

  OnboardingIdle copyWith({int? currentPage}) =>
      OnboardingIdle(currentPage: currentPage ?? this.currentPage);
}

final class OnboardingDone extends OnboardingState {
  const OnboardingDone() : super(currentPage: 0);
}
