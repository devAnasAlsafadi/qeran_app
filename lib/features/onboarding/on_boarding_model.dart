/// The three ordered frames of the onboarding wizard.
///
/// `onboardingData.length == 3` drives `OnboardingCubit` / `OnboardingState`
/// pagination (`isFirstPage` / `isLastPage`), which read the list length. The
/// top-level `onboardingData` symbol is preserved verbatim so the cubit and its
/// state stay untouched — only the element type changes (image-model → frame).
/// (The former wine brand-splash frame was retired; the splash animation owns
/// that moment now, so onboarding opens directly on the community slide.)
enum OnboardingFrame { community, mediation, roadmap }

/// Ordered page list — one entry per wizard page. Consumed by the screen's
/// `PageView` and by the cubit's page math.
const List<OnboardingFrame> onboardingData = OnboardingFrame.values;
