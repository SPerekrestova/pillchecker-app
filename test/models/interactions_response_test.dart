import 'package:flutter_test/flutter_test.dart';
import 'package:pillchecker_app/models/interactions_response.dart';

void main() {
  group('InteractionsResponse.fromJson', () {
    test('parses safe response with no interactions', () {
      final json = {
        'interactions': <Map<String, dynamic>>[],
        'safe': true,
      };

      final response = InteractionsResponse.fromJson(json);

      expect(response.safe, isTrue);
      expect(response.interactions, isEmpty);
    });

    test('parses unsafe response with interactions', () {
      final json = {
        'interactions': [
          {
            'drug_a': 'Ibuprofen',
            'drug_b': 'Warfarin',
            'severity': 'Major',
            'description': 'Risk',
            'management': 'Avoid',
          },
        ],
        'safe': false,
      };

      final response = InteractionsResponse.fromJson(json);

      expect(response.safe, isFalse);
      expect(response.interactions.length, 1);
      expect(response.interactions[0].drugA, 'Ibuprofen');
    });

    test('parses multiple interactions', () {
      final json = {
        'interactions': [
          {
            'drug_a': 'A',
            'drug_b': 'B',
            'severity': 'Major',
            'description': 'd1',
            'management': 'm1',
          },
          {
            'drug_a': 'A',
            'drug_b': 'C',
            'severity': 'Minor',
            'description': 'd2',
            'management': 'm2',
          },
        ],
        'safe': false,
      };

      final response = InteractionsResponse.fromJson(json);
      expect(response.interactions.length, 2);
    });
  });
}
