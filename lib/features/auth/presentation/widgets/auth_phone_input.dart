import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/widgets/qeran_text_field.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/utils/phone_validator.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import 'country_code_picker.dart';

class AuthPhoneInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueNotifier<String> countryCodeNotifier;
  final String? Function(String?)? validator;

  const AuthPhoneInput({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.countryCodeNotifier,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: countryCodeNotifier,
      builder: (context, countryCode, child) {
        // Phone numbers are universally LTR — the country code sits on the
        // left of the digits regardless of UI language. Lock this row to LTR
        // so the layout does not flip between Arabic and English. Scoped to
        // the Row via textDirection — not the forbidden Directionality widget.
        return Row(
          textDirection: TextDirection.ltr,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CountryCodePicker(
              selectedCode: countryCode,
              onChanged: (code) => countryCodeNotifier.value = code,
            ),
            const SizedBox(width: QeranSpacing.s8),
            Expanded(
              child: QeranTextField(
                controller: controller,
                focusNode: focusNode,
                hint: LocaleKeys.auth_phone_hint.t(context),
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                validator: validator ?? PhoneValidator.validate,
              ),
            ),
          ],
        );
      },
    );
  }
}
