import 'package:equatable/equatable.dart';

/// The formal-request progress attached to an active match (MatchCardDto
/// `formalRequest`). Read-only: the matchmaker sees the backend-provided
/// [statusNameAr] / [statusNameEn] verbatim — we never map [status] (1-5)
/// to our own copy here.
class MatchmakerInterestFormalRequest extends Equatable {
  final int status;
  final String statusNameAr;
  final String statusNameEn;

  const MatchmakerInterestFormalRequest({
    required this.status,
    required this.statusNameAr,
    required this.statusNameEn,
  });

  @override
  List<Object?> get props => [status, statusNameAr, statusNameEn];
}
