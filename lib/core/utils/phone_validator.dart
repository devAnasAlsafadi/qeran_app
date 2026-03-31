class PhoneValidator {
  static String? validate(String? localNumber) {
    if (localNumber == null || localNumber.trim().isEmpty) {
      return 'رقم الهاتف مطلوب';
    }
    final cleaned = localNumber.trim().replaceAll(RegExp(r'\s+'), '');
    if (RegExp(r'[^0-9]').hasMatch(cleaned)) {
      return 'رقم الهاتف يجب أن يحتوي على أرقام فقط';
    }
    if (cleaned.length < 7) {
      return 'رقم الهاتف قصير جداً';
    }
    return null;
  }
}
