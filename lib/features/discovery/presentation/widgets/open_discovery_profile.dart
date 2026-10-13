import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/routes/navigation_manager.dart';
import 'package:qeran/core/routes/route_name.dart';
import 'package:qeran/core/utils/keyboard_dismissal.dart';

import '../../../profile/domain/entities/profile_entry_source.dart';
import '../../../profile/presentation/full_profile_details_args.dart';
import '../../../profile/presentation/other_profile_seed.dart';
import '../../domain/entities/discovery_profile.dart';
import '../blocs/discovery_cubit.dart';

/// Opens the full profile of the member on a Suggestions card — from its
/// photo or its name (run 7). Report and Block live there, behind its ⋮, one
/// tap from the card (Apple 1.2), as they did before the card became the
/// profile (`5648f961`).
///
/// A block closes that screen with the member's id; they then leave the deck
/// — the next card in their place, no reload (`DiscoveryCubit.drop`).
Future<void> openDiscoveryProfile(
  BuildContext context,
  DiscoveryProfile profile,
) async {
  // Visited tabs stay mounted: nothing left focused offstage for Android to
  // hand the keyboard back to when this route pops.
  unawaited(dismissKeyboard());
  final cubit = context.read<DiscoveryCubit>();
  final result = await NavigationManager.navigateTo(
    context,
    RouteNames.fullProfileDetails,
    arguments: FullProfileDetailsArgs(
      userId: profile.id,
      initialData: OtherProfileSeed.fromDiscovery(profile),
      entry: ProfileEntrySource.discovery,
    ),
  );
  if (result is String) cubit.drop(result);
}
