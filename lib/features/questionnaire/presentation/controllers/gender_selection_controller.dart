import 'package:flutter/foundation.dart';
import 'package:qeran/core/constants/storage_keys.dart';
import 'package:qeran/core/datasources/shared_pref_service.dart';
import 'package:qeran/core/enum/gender.dart';

class GenderSelectionController {
  final SharedPrefService _sharedPrefs;

  GenderSelectionController({required SharedPrefService sharedPrefs})
      : _sharedPrefs = sharedPrefs;

  final ValueNotifier<Gender?> selectedGenderNotifier =
      ValueNotifier<Gender?>(null);

  Gender? get selectedGender => selectedGenderNotifier.value;

  void selectGender(Gender gender) {
    selectedGenderNotifier.value = gender;
  }

  /// Persists the selected gender locally before question fetching.
  Future<void> saveGender() async {
    if (selectedGender == null) return;
    await _sharedPrefs.save(StorageKeys.gender, selectedGender!.apiValue);
  }

  void dispose() {
    selectedGenderNotifier.dispose();
  }
}
