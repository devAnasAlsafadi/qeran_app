import 'package:equatable/equatable.dart';

import '../../../domain/entities/profile_image.dart';

enum ProfilePhotosStatus { initial, loading, loaded, failure }

enum ProfilePhotoAction { upload, delete, setMain }

enum ProfilePhotoEvent {
  none,
  uploaded,
  deleted,
  mainChanged,
  maxReached,
  validationFailure,
  actionFailure,
}

class ProfilePhotosState extends Equatable {
  const ProfilePhotosState({
    this.status = ProfilePhotosStatus.initial,
    this.images = const [],
    this.inFlight,
    this.inFlightImageId,
    this.event = ProfilePhotoEvent.none,
    this.eventVersion = 0,
    this.errorMessage,
  });

  final ProfilePhotosStatus status;
  final List<OwnerImage> images;
  final ProfilePhotoAction? inFlight;
  final String? inFlightImageId;
  final ProfilePhotoEvent event;
  final int eventVersion;
  final String? errorMessage;

  bool get isBusy => inFlight != null;
  bool get canAddMore => images.length < 5;

  ProfilePhotosState copyWith({
    ProfilePhotosStatus? status,
    List<OwnerImage>? images,
    ProfilePhotoAction? inFlight,
    bool clearInFlight = false,
    String? inFlightImageId,
    ProfilePhotoEvent? event,
    int? eventVersion,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ProfilePhotosState(
      status: status ?? this.status,
      images: images ?? this.images,
      inFlight: clearInFlight ? null : (inFlight ?? this.inFlight),
      inFlightImageId: clearInFlight
          ? null
          : (inFlightImageId ?? this.inFlightImageId),
      event: event ?? this.event,
      eventVersion: eventVersion ?? this.eventVersion,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
    status,
    images,
    inFlight,
    inFlightImageId,
    event,
    eventVersion,
    errorMessage,
  ];
}
