part of 'support_cubit.dart';

/// Load phase for the problem-type dropdown.
enum SupportCategoriesStatus { loading, loaded, failure }

/// Submission phase for the support request.
enum SupportSubmitStatus { idle, submitting, success, failure }

class SupportState extends Equatable {
  final SupportCategoriesStatus categoriesStatus;
  final List<SupportCategory> categories;

  /// Locale key for the categories-load error (shown via QeranErrorState).
  final String categoriesErrorKey;

  final SupportSubmitStatus submitStatus;

  /// Message for the post-submit toast — a backend string on failure (already
  /// localized) or a locale key on success; render via `.t(context)`
  /// (a no-op for a non-key string).
  final String submitMessage;

  /// True when the failure was the 5-open-tickets cap — lets the screen treat
  /// it as an informational limit rather than a hard error.
  final bool submitLimitReached;

  /// Bumped on every terminal submit outcome so the screen reacts exactly once
  /// (toast on success/failure, pop on success).
  final int eventVersion;

  const SupportState({
    this.categoriesStatus = SupportCategoriesStatus.loading,
    this.categories = const [],
    this.categoriesErrorKey = LocaleKeys.errors_generic,
    this.submitStatus = SupportSubmitStatus.idle,
    this.submitMessage = '',
    this.submitLimitReached = false,
    this.eventVersion = 0,
  });

  bool get isSubmitting => submitStatus == SupportSubmitStatus.submitting;

  SupportState copyWith({
    SupportCategoriesStatus? categoriesStatus,
    List<SupportCategory>? categories,
    String? categoriesErrorKey,
    SupportSubmitStatus? submitStatus,
    String? submitMessage,
    bool? submitLimitReached,
    int? eventVersion,
  }) {
    return SupportState(
      categoriesStatus: categoriesStatus ?? this.categoriesStatus,
      categories: categories ?? this.categories,
      categoriesErrorKey: categoriesErrorKey ?? this.categoriesErrorKey,
      submitStatus: submitStatus ?? this.submitStatus,
      submitMessage: submitMessage ?? this.submitMessage,
      submitLimitReached: submitLimitReached ?? this.submitLimitReached,
      eventVersion: eventVersion ?? this.eventVersion,
    );
  }

  @override
  List<Object?> get props => [
        categoriesStatus,
        categories,
        categoriesErrorKey,
        submitStatus,
        submitMessage,
        submitLimitReached,
        eventVersion,
      ];
}
