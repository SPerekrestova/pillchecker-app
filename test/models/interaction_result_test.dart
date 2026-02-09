import 'package:flutter_test/flutter_test.dart';
import 'package:pillchecker_app/models/interaction_result.dart';

void main() {
  group('InteractionResult.fromJson', () {
    test('parses all fields with snake_case keys', () {
      final json = {
        'drug_a': 'Ibuprofen',
        'drug_b': 'Warfarin',
        'severity': 'Major',
        'description': 'Increased bleeding risk',
        'management': 'Avoid combination',
      };

      final result = InteractionResult.fromJson(json);

      expect(result.drugA, 'Ibuprofen');
      expect(result.drugB, 'Warfarin');
      expect(result.severity, 'Major');
      expect(result.description, 'Increased bleeding risk');
      expect(result.management, 'Avoid combination');
    });

    test('preserves severity case as-is from backend', () {
      final json = {
        'drug_a': 'A',
        'drug_b': 'B',
        'severity': 'moderate',
        'description': 'desc',
        'management': '',
      };

      final result = InteractionResult.fromJson(json);
      expect(result.severity, 'moderate');
    });

    test('handles empty management string', () {
      final json = {
        'drug_a': 'A',
        'drug_b': 'B',
        'severity': 'Minor',
        'description': 'Mild interaction',
        'management': '',
      };

      final result = InteractionResult.fromJson(json);
      expect(result.management, isEmpty);
    });
  });
}
