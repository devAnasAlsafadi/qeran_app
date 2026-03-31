import 'package:flutter/material.dart';
import '../../../../core/utils/app_dimens.dart';
import '../../../../core/widgets/app_text_form_field.dart';
import '../../../../core/utils/phone_validator.dart';
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
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AppTextFormField(
                controller: controller,
                focusNode: focusNode,
                hintText: 'رقم الهاتف',
                obscureText: false,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                validator: validator ?? PhoneValidator.validate,
              ),
            ),
            const SizedBox(width: AppDimens.p8),
            CountryCodePicker(
              selectedCode: countryCode,
              onChanged: (code) => countryCodeNotifier.value = code,
            ),
          ],
        );
      },
    );
  }
}
