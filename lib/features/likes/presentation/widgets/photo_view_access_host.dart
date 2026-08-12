import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/design_system/widgets/qeran_confirm_dialog.dart';
import 'package:qeran/core/enum/snakebar_tybe.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/utils/app_snackbar.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../blocs/photo_view_cubit.dart';
import '../blocs/photo_view_state.dart';

/// Connects a protected photo surface to [PhotoViewCubit], including the
/// irreversible confirmation and app-lifecycle privacy concealment.
class PhotoViewAccessHost extends StatefulWidget {
  final Widget child;
  final bool observeLifecycle;

  const PhotoViewAccessHost({
    super.key,
    required this.child,
    this.observeLifecycle = true,
  });

  @override
  State<PhotoViewAccessHost> createState() => _PhotoViewAccessHostState();
}

class _PhotoViewAccessHostState extends State<PhotoViewAccessHost>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    if (widget.observeLifecycle) WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    if (widget.observeLifecycle) WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final cubit = context.read<PhotoViewCubit>();
    switch (state) {
      case AppLifecycleState.resumed:
        cubit.load();
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        cubit.conceal();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PhotoViewCubit, PhotoViewState>(
      listenWhen: (previous, current) =>
          previous.eventVersion != current.eventVersion &&
          (current.actionErrorMessage != null || current.justExpired),
      listener: _onEvent,
      child: BlocBuilder<PhotoViewCubit, PhotoViewState>(
        builder: (context, state) => PhotoViewScope(
          state: state,
          onReveal: () => _confirmReveal(context),
          onRetry: () => context.read<PhotoViewCubit>().load(),
          onImageForbidden: () =>
              context.read<PhotoViewCubit>().markImageAccessConsumed(),
          child: widget.child,
        ),
      ),
    );
  }

  /// The window closing is not an error — it is the expected end of a
  /// one-time view, and with the countdown badge gone it is the only signal
  /// the member gets. It is announced calmly; a real action failure keeps the
  /// error treatment.
  void _onEvent(BuildContext context, PhotoViewState state) {
    if (state.justExpired) {
      AppSnackBar.show(
        context,
        message: LocaleKeys.likes_matches_photo_view_expired.t(context),
        type: SnackBarType.info,
      );
      return;
    }
    AppSnackBar.show(
      context,
      message: (state.actionErrorMessage ?? LocaleKeys.errors_generic).t(
        context,
      ),
      type: SnackBarType.error,
    );
  }

  Future<void> _confirmReveal(BuildContext context) async {
    final confirmed = await QeranConfirmDialog.show(
      context,
      title: LocaleKeys.likes_matches_photo_view_confirm_title.t(context),
      message: LocaleKeys.likes_matches_photo_view_confirm_message.t(context),
      confirmLabel: LocaleKeys.likes_matches_photo_view_show.t(context),
      icon: Icons.visibility_outlined,
      destructive: false,
    );
    if (confirmed && context.mounted) {
      context.read<PhotoViewCubit>().beginViewing();
    }
  }
}

/// Access policy inherited by every protected image below the host.
class PhotoViewScope extends InheritedWidget {
  final PhotoViewState state;
  final VoidCallback onReveal;
  final VoidCallback onRetry;
  final VoidCallback onImageForbidden;

  const PhotoViewScope({
    super.key,
    required this.state,
    required this.onReveal,
    required this.onRetry,
    required this.onImageForbidden,
    required super.child,
  });

  static PhotoViewScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PhotoViewScope>();

  /// `unavailable` means there is no accepted exchange; preserve the normal
  /// per-image server blur flags and ordinary image pipeline.
  bool get controlsAccess => state.phase != PhotoViewPhase.unavailable;

  bool get isActivelyViewing =>
      state.phase == PhotoViewPhase.viewing && !state.isConcealed;

  /// Never fetch original bytes before reveal, after expiry, while permission
  /// is unknown, or while the app is inactive.
  bool get blockImageBytes => controlsAccess && !isActivelyViewing;

  /// During the window use Flutter's in-memory [NetworkImage], never the disk
  /// cache used by CachedNetworkImage.
  bool get memoryOnly => controlsAccess && isActivelyViewing;

  bool effectiveBlur(bool serverBlur) =>
      controlsAccess ? !isActivelyViewing : serverBlur;

  @override
  bool updateShouldNotify(PhotoViewScope oldWidget) => state != oldWidget.state;
}
