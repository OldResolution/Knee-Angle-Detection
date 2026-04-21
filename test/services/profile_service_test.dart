import 'package:flutter_test/flutter_test.dart';
import 'package:gopal_app/services/profile_service.dart';

void main() {
  group('ProfileService.mergeProfileData', () {
    test('prefers explicit profile row values over metadata fallbacks', () {
      final merged = ProfileService.mergeProfileData(
        metadata: const {
          'name': 'Metadata Name',
          'mobile': '1111111111',
          'gender': 'Other',
        },
        profileRow: const {
          'name': 'Profile Name',
          'email': 'person@example.com',
          'age': 28,
        },
      );

      expect(merged['name'], 'Profile Name');
      expect(merged['mobile'], '1111111111');
      expect(merged['email'], 'person@example.com');
      expect(merged['age'], 28);
      expect(merged['gender'], 'Other');
    });

    test('drops null values from the merged payload', () {
      final merged = ProfileService.mergeProfileData(
        metadata: const {
          'name': 'Metadata Name',
          'mobile': null,
        },
        profileRow: const {
          'email': 'person@example.com',
        },
      );

      expect(merged.containsKey('mobile'), isFalse);
      expect(merged['name'], 'Metadata Name');
      expect(merged['email'], 'person@example.com');
    });
  });
}
