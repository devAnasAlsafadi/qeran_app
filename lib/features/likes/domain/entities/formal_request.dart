import 'package:equatable/equatable.dart';

/// Matchmaker-side formal request attached to a stage-1 match.
///
/// Backend server-localizes the status name into `statusNameAr` /
/// `statusNameEn` — the UI picks one based on the current app locale
/// and renders it verbatim (NO `.tr()`). The raw [status] string is
/// kept for logging / future filtering.
class FormalRequest extends Equatable {
  final int id;
  final String maleUserId;
  final String maleUserName;
  final String femaleUserId;
  final String femaleUserName;
  final String status;
  final String statusNameAr;
  final String statusNameEn;
  final DateTime? updatedByMatchmakerAt;
  final DateTime createdAt;

  const FormalRequest({
    required this.id,
    required this.maleUserId,
    required this.maleUserName,
    required this.femaleUserId,
    required this.femaleUserName,
    required this.status,
    required this.statusNameAr,
    required this.statusNameEn,
    required this.updatedByMatchmakerAt,
    required this.createdAt,
  });

  /// Pick the locale-appropriate, server-supplied status name.
  /// Empty strings fall through so the UI can substitute a neutral
  /// fallback subtitle.
  String localizedStatusName(String languageCode) {
    if (languageCode == 'ar' && statusNameAr.isNotEmpty) return statusNameAr;
    if (statusNameEn.isNotEmpty) return statusNameEn;
    if (statusNameAr.isNotEmpty) return statusNameAr;
    return '';
  }

  @override
  List<Object?> get props => [
        id,
        maleUserId,
        maleUserName,
        femaleUserId,
        femaleUserName,
        status,
        statusNameAr,
        statusNameEn,
        updatedByMatchmakerAt,
        createdAt,
      ];
}
