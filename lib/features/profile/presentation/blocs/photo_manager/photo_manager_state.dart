import 'package:equatable/equatable.dart';

import '../../../domain/entities/photo_slot.dart';
import '../../../domain/entities/profile_image.dart';

/// Where the photo manager is mounted. The screen shell is identical in
/// both; only the chrome and the available actions differ.
enum PhotoManagerMode {
  /// Registration flow — progress bar, skip, batch upload, then home.
  onboarding,

  /// Profile edit — app bar, delete and set-main on server photos.
  profileEdit,
}

enum PhotoManagerStatus { initial, loading, loaded, failure }

enum PhotoManagerAction { upload, delete, setMain }

enum PhotoManagerEvent {
  none,
  uploaded,
  deleted,
  mainChanged,
  maxReached,
  validationFailure,
  actionFailure,

  /// Upload succeeded or was skipped — onboarding navigates away.
  finished,
}

/// Maximum photos per profile, counting server and staged together.
const int kMaxProfilePhotos = 5;

class PhotoManagerState extends Equatable {
  const PhotoManagerState({
    required this.mode,
    this.status = PhotoManagerStatus.initial,
    this.serverImages = const [],
    this.stagedPaths = const [],
    this.stagedMainPath,
    this.inFlight,
    this.inFlightImageId,
    this.event = PhotoManagerEvent.none,
    this.eventVersion = 0,
    this.errorMessage,
    this.successMessage,
  });

  final PhotoManagerMode mode;
  final PhotoManagerStatus status;

  /// Photos already persisted, newest server order preserved.
  final List<OwnerImage> serverImages;

  /// Local file paths picked but not uploaded yet.
  final List<String> stagedPaths;

  /// The staged photo the user marked as main, if any. Non-null means the
  /// user's main choice has not reached the server yet.
  final String? stagedMainPath;

  final PhotoManagerAction? inFlight;
  final String? inFlightImageId;
  final PhotoManagerEvent event;
  final int eventVersion;
  final String? errorMessage;
  final String? successMessage;

  bool get isBusy => inFlight != null;

  bool get hasStaged => stagedPaths.isNotEmpty;

  /// Server photos first, then staged ones — the order the grid renders.
  ///
  /// Server photos are ordered by **id**, deliberately NOT by payload order.
  /// The server sorts `IsProfile DESC, CreatedAt DESC, Id`, so the main photo
  /// always leads — which means a successful set-main returns the whole list
  /// reshuffled: the tile the user just tapped teleports to slot 0 and the
  /// badge reads as having landed on some other photo. Sorting on a key no
  /// mutation can change keeps every tile where it is, so only the badge
  /// moves. Per Tariq: `isProfile` says WHICH photo is main; payload order
  /// says nothing about where it sits.
  ///
  /// `id` is a GUID, so the resulting order is arbitrary — but arbitrary and
  /// STABLE beats meaningful and shifting for a five-tile grid the user
  /// reaches into. Ids are unique, so `sort`'s instability cannot bite.
  List<PhotoSlot> get slots => [
    ...(<OwnerImage>[...serverImages]..sort((a, b) => a.id.compareTo(b.id)))
        .map(ServerPhotoSlot.new),
    ...stagedPaths.map(
      (path) =>
          StagedPhotoSlot(path: path, isMain: path == stagedMainPath),
    ),
  ];

  /// The cap counts both kinds — three on the server plus two staged is
  /// already five.
  int get totalCount => serverImages.length + stagedPaths.length;

  bool get canAddMore => totalCount < kMaxProfilePhotos;

  PhotoManagerState copyWith({
    PhotoManagerStatus? status,
    List<OwnerImage>? serverImages,
    List<String>? stagedPaths,
    String? stagedMainPath,
    bool clearStagedMain = false,
    PhotoManagerAction? inFlight,
    bool clearInFlight = false,
    String? inFlightImageId,
    PhotoManagerEvent? event,
    int? eventVersion,
    String? errorMessage,
    bool clearError = false,
    String? successMessage,
  }) {
    return PhotoManagerState(
      mode: mode,
      status: status ?? this.status,
      serverImages: serverImages ?? this.serverImages,
      stagedPaths: stagedPaths ?? this.stagedPaths,
      stagedMainPath: clearStagedMain
          ? null
          : (stagedMainPath ?? this.stagedMainPath),
      inFlight: clearInFlight ? null : (inFlight ?? this.inFlight),
      inFlightImageId: clearInFlight
          ? null
          : (inFlightImageId ?? this.inFlightImageId),
      event: event ?? this.event,
      eventVersion: eventVersion ?? this.eventVersion,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: successMessage ?? this.successMessage,
    );
  }

  @override
  List<Object?> get props => [
    mode,
    status,
    serverImages,
    stagedPaths,
    stagedMainPath,
    inFlight,
    inFlightImageId,
    event,
    eventVersion,
    errorMessage,
    successMessage,
  ];
}
