import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Rebuilds [child] from scratch whenever the app language changes.
///
/// Changing the locale already repaints every `tr()` string — `Localizations`
/// rebuilds its dependents. What it does NOT do is re-ask the server: anything
/// a screen fetched before the switch (placement labels, chip values, section
/// titles — all of it server-localised) is still in the old language, and a
/// shell that keeps its tabs alive will happily show that forever.
///
/// Keying on the language code discards the subtree and builds a new one, so
/// the screen's cubits are created fresh and fetch again under the new
/// `Accept-Language`. Deliberately heavy-handed: a language switch is rare,
/// deliberate, and expected to reload the app — far better than a screen that
/// stays half-translated until the user thinks to pull to refresh.
///
/// Wrap the CONTENT of a long-lived shell slot, not the slot itself, so the
/// host keeps its own identity (and its tab/scroll bookkeeping) across the
/// rebuild.
class LocaleRebuildScope extends StatelessWidget {
  const LocaleRebuildScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: ValueKey<String>('locale-${context.locale.languageCode}'),
      child: child,
    );
  }
}
