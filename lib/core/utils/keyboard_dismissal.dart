import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Clears Flutter focus and explicitly asks the platform IME to close.
///
/// Clearing both layers matters around route transitions: Android can restore
/// a previously focused, now-offstage text field when the top route pops even
/// though the destination screen itself has no editable field.
Future<void> dismissKeyboard() async {
  FocusManager.instance.primaryFocus?.unfocus();
  await SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
}
