import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/theme/app_color.dart';
import 'package:qeran/core/utils/app_dimens.dart';

class CountryCodePicker extends StatelessWidget {
  final String selectedCode;
  final ValueChanged<String> onChanged;

  const CountryCodePicker({
    super.key,
    required this.selectedCode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final country = CountryParser.parsePhoneCode(
      selectedCode.replaceFirst('+', ''),
    );

    return GestureDetector(
      onTap: () => _showPicker(context),
      child: Container(
        height: 55,
        padding: const EdgeInsets.symmetric(horizontal: AppDimens.p12),
        decoration: BoxDecoration(
          color: AppColors.greyLight,
          borderRadius: AppDimens.borderRadius12,
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(country.flagEmoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: AppDimens.p4),
            Text(
              '+${country.phoneCode}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(width: AppDimens.p4),
            const Icon(
              Icons.keyboard_arrow_down,
              size: 18,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  void _showPicker(BuildContext context) {
    showCountryPicker(
      context: context,
      favorite: ['PS', 'SA', 'AE', 'JO', 'EG', 'KW', 'QA', 'BH', 'OM', 'LB'],
      showPhoneCode: true,
      countryListTheme: CountryListThemeData(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDimens.r16),
        ),
        inputDecoration: InputDecoration(
          hintText: 'auth.country_search_hint'.t(context),
          hintTextDirection: TextDirection.rtl,
          prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
          filled: true,
          fillColor: AppColors.greyLight,
          contentPadding: const EdgeInsets.symmetric(vertical: AppDimens.p12),
          border: OutlineInputBorder(
            borderRadius: AppDimens.borderRadius12,
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: AppDimens.borderRadius12,
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: AppDimens.borderRadius12,
            borderSide: const BorderSide(color: AppColors.primary),
          ),
        ),
      ),
      onSelect: (country) => onChanged('+${country.phoneCode}'),
    );
  }
}
