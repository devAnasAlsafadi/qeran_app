import 'package:qeran/features/home/domain/entities/profile_entity.dart';

/// TEMPORARY — visual-only fixtures used to preview the Home card before
/// the data layer (API + repository) is wired. Delete this file once
/// `GetCandidateProfilesUseCase` is in place.
class MockProfiles {
  MockProfiles._();

  static const List<ProfileEntity> deck = [
    ProfileEntity(
      id: 'mock-1',
      name: 'أحمد صالح',
      age: 26,
      city: 'الرياض',
      country: 'السعودية',
      occupation: 'مهندس برمجيات',
      bio:
          'شخصية طموحة ومحبة للتطوير الذاتي، أبحث عن شريك حياة يشاركني نفس '
          'القيم والاهتمامات',
      religion: 'مسلم',
      heightCm: 175,
      weightKg: 60,
    ),
    ProfileEntity(
      id: 'mock-2',
      name: 'يوسف عمر',
      age: 29,
      city: 'جدة',
      country: 'السعودية',
      occupation: 'طبيب أسنان',
      bio:
          'أحب القراءة والرياضة، وأسعى لبناء حياة هادئة قائمة على المودة '
          'والاحترام.',
      religion: 'مسلم',
      heightCm: 182,
      weightKg: 78,
    ),
  ];
}
