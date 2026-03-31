enum Gender {
  male,
  female;

  String get apiValue => switch (this) {
        Gender.male => 'Male',
        Gender.female => 'Female',
      };
}
