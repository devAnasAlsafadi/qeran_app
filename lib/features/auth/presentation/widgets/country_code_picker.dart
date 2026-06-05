import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/extensions/localization_extension.dart';

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

    // Mirrors QeranTextField's box (paper fill, control radius,
    // hairline border, s12 vertical rhythm) so the picker and the phone
    // field read as one matched pair, top-aligned in the row.
    return GestureDetector(
      onTap: () => _showPicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: QeranSpacing.s12,
          vertical: QeranSpacing.s12,
        ),
        decoration: BoxDecoration(
          color: QeranColors.paper,
          borderRadius: QeranRadii.controlR,
          border: Border.all(color: QeranColors.hairline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Flag is an emoji glyph — only its size matters and no typography
            // token expresses size-only, so a raw fontSize is used here.
            Text(country.flagEmoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: QeranSpacing.s4),
            Text(
              '+${country.phoneCode}',
              style: QeranTypography.body.copyWith(color: QeranColors.inkStrong),
            ),
            const SizedBox(width: QeranSpacing.s4),
            const Icon(
              Icons.keyboard_arrow_down,
              size: 18,
              color: QeranColors.inkMuted,
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
          top: Radius.circular(QeranRadii.dome),
        ),
        inputDecoration: InputDecoration(
          hintText: 'auth.country_search_hint'.t(context),
          hintTextDirection: TextDirection.rtl,
          prefixIcon: const Icon(Icons.search, color: QeranColors.inkMuted),
          filled: true,
          fillColor: QeranColors.paper,
          contentPadding: const EdgeInsets.symmetric(
            vertical: QeranSpacing.s12,
          ),
          border: OutlineInputBorder(
            borderRadius: QeranRadii.controlR,
            borderSide: const BorderSide(color: QeranColors.hairline),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: QeranRadii.controlR,
            borderSide: const BorderSide(color: QeranColors.hairline),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: QeranRadii.controlR,
            borderSide: const BorderSide(color: QeranColors.wine),
          ),
        ),
      ),
      onSelect: (country) => onChanged('+${country.phoneCode}'),
    );
  }
}
