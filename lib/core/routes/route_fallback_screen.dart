import 'package:flutter/material.dart';

import '../../generated/locale_keys.g.dart';
import '../design_system/widgets/qeran_app_bar.dart';
import '../design_system/widgets/qeran_error_state.dart';
import '../extensions/localization_extension.dart';

/// What the router shows when a screen can't open: a route it doesn't know,
/// or one that arrived without its arguments (a stale notification, a bad
/// push). «حدث خطأ، حاول مرة أخرى» and the way back, never developer text
/// (cleanup audit `19`, run 11).
class RouteFallbackScreen extends StatelessWidget {
  const RouteFallbackScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const QeranAppBar(),
    body: QeranErrorState(title: LocaleKeys.errors_generic.t(context)),
  );
}
