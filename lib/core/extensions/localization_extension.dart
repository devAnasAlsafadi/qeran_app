import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

extension LocalizationExtension on String {
  String t(BuildContext context) => context.tr(this);
}
