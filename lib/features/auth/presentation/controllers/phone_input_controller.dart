import 'package:flutter/material.dart';

import '../../../../core/utils/phone_formatter.dart';

class PhoneInputController {
  final phoneController = TextEditingController();
  final phoneFocus = FocusNode();
  final formKey = GlobalKey<FormState>();
  final ValueNotifier<String> countryCodeNotifier = ValueNotifier<String>('+970');

  String get selectedCountryCode => countryCodeNotifier.value;

  bool validate() => formKey.currentState?.validate() ?? false;


  String? validateAndGetFormattedPhone() {
    if (formKey.currentState?.validate() ?? false) {
      return PhoneFormatter.toApiFormat(
        selectedCountryCode,
        phoneController.text,
      );
    }
    return null;
  }


  void dispose() {
    phoneController.dispose();
    phoneFocus.dispose();
    countryCodeNotifier.dispose();
  }
}
