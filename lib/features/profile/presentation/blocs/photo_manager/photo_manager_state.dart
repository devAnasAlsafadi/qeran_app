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

enum PhotoManagerAction {
  upload,
  delete,
  setMain,

  /// Uploading ONE staged photo and promoting it in a single user action.
  /// Distinct from [upload] so the batch lights every staged tile while this
  /// lights only the photo the user tapped.
  promoteStaged,
}

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
    this.inFlightPhotoIds = const {},
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

  /// The screen-wide lock. Non-null means a mutation owns the screen, which
  /// is what stops a second one interleaving — NOT what decides which tile
  /// shows a loader. See [inFlightPhotoIds] for that.
  final PhotoManagerAction? inFlight;

  /// Ids of the photos currently mutating, so a loader can be scoped to the
  /// tiles actually affected instead of dimming the whole grid.
  ///
  /// Holds at most one id while [inFlight] serialises mutations; it is a set
  /// so per-photo work can fan out later without reshaping the state.
  final Set<String> inFlightPhotoIds;

  final PhotoManagerEvent event;
  final int eventVersion;
  final String? errorMessage;
  final String? successMessage;

  bool get isBusy => inFlight != null;

  /// True only for a photo this mutation actually touches.
  bool isPhotoInFlight(String id) => inFlightPhotoIds.contains(id);

  /// Whether THIS tile should render a loader.
  ///
  /// Scoped on purpose: a set-main or delete owns one photo, so dimming the
  /// rest of the grid told the user their whole library was busy when a
  /// single tile was. Staged tiles have no server id yet and never mutate
  /// alone — the batch upload takes all of them at once, so that is the only
  /// action that lights them up.
  bool isSlotLoading(PhotoSlot slot) => switch (slot) {
    ServerPhotoSlot(:final id) => isPhotoInFlight(id),
    // A batch upload takes every staged file, so all of them light up. The
    // atomic promotion takes one, tracked by its path.
    StagedPhotoSlot(:final path) =>
      inFlight == PhotoManagerAction.upload || isPhotoInFlight(path),
  };

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
    Set<String>? inFlightPhotoIds,
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
      // Deliberately NOT tied to clearInFlight: the id set is released in the
      // `finally` of the mutation that claimed it, so a throw between the two
      // can never strand a tile mid-spinner.
      inFlightPhotoIds: inFlightPhotoIds ?? this.inFlightPhotoIds,
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
    inFlightPhotoIds,
    event,
    eventVersion,
    errorMessage,
    successMessage,
  ];
}
