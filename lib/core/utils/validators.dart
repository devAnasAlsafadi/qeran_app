class Validators {
  static final RegExp emailPattern =
  RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

  // static final RegExp passwordPattern =
  // RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{8,}$');



  static final RegExp passwordPattern = RegExp(
      r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[^A-Za-z\d]).{8,}$'
  );



  static String? validateEmail(String? val) {
    if (val == null || val.isEmpty) return 'Please fill in this field';
    if (!emailPattern.hasMatch(val)) return 'Please enter a valid email';
    return null;
  }

  static String? validatePassword(String? val) {
    if (val == null || val.isEmpty) {
      return 'Please fill in this field';
    }

    if (val.length < 8) {
      return 'Password must be at least 8 characters';
    }

    return null;
  }

  // static String? validatePassword(String? val) {
  //   if (val == null || val.isEmpty) return 'Please fill in this field';
  //   if (!passwordPattern.hasMatch(val)) {
  //     return 'Password must be at least 8 characters and include letters and numbers';
  //   }
  //   return null;
  // }
}
