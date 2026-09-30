import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/discovery_cubit.dart';
import '../screens/discovery_filter_sheet.dart';

/// Opens the dynamic filter sheet and forwards the user's selections
/// into [DiscoveryCubit.applyFilters].
///
/// The sheet is seeded with the deck's currently-applied selections so
/// previously-picked facets show as selected. On Save:
/// * Dismissed (null result) → no-op (keeps the applied filters).
/// * Empty payload → applies `null` (clears active filters).
/// * Non-empty payload → applies it; the cubit reloads from page 1 and
///   future prefetches carry the same params.
///
/// Either way the structured selections are written back so the next open
/// reflects the applied state.
Future<void> openDiscoveryFilters(BuildContext context) async {
  final cubit = context.read<DiscoveryCubit>();
  final result = await showDiscoveryFilterSheet(
    context,
    initialSelections: cubit.activeFilterSelections,
  );
  if (result == null) return;
  if (!context.mounted) return;
  final payload = result.payload;
  await cubit.applyFilters(
    payload.isEmpty ? null : payload,
    selections: result.selections,
  );
}
