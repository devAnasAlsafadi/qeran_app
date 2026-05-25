import 'package:flutter/material.dart';
import 'package:qeran/generated/locale_keys.g.dart';
import '../../../../core/extensions/localization_extension.dart';
import '../../../../core/utils/app_dimens.dart';
import '../../../../core/utils/phone_validator.dart';
import '../../../../core/widgets/app_text_form_field.dart';
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
        // left of the digits regardless of UI language. Force this row's
        // text direction (and the children's order) to LTR so the layout
        // does not flip between Arabic and English.
        return Row(
          textDirection: TextDirection.ltr,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CountryCodePicker(
              selectedCode: countryCode,
              onChanged: (code) => countryCodeNotifier.value = code,
            ),
            const SizedBox(width: AppDimens.p8),
            Expanded(
              child: AppTextFormField(
                controller: controller,
                focusNode: focusNode,
                hintText: LocaleKeys.auth_phone_hint.t(context),
                obscureText: false,
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
