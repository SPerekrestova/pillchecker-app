import 'package:flutter_test/flutter_test.dart';
import 'package:pillchecker_app/models/analyze_response.dart';

void main() {
  group('AnalyzeResponse.fromJson', () {
    test('parses response with multiple drugs', () {
      final json = {
        'drugs': [
          {
            'rxcui': '5640',
            'name': 'Ibuprofen',
            'dosage': '400mg',
            'form': 'tablet',
            'source': 'ner',
            'confidence': 0.95,
          },
          {
            'rxcui': '1191',
            'name': 'Aspirin',
            'dosage': null,
            'form': null,
            'source': 'rxnorm_fallback',
            'confidence': 0.7,
          },
        ],
        'raw_text': 'BRUFEN Ibuprofen 400mg Aspirin',
      };

      final response = AnalyzeResponse.fromJson(json);

      expect(response.drugs.length, 2);
      expect(response.drugs[0].name, 'Ibuprofen');
      expect(response.drugs[1].name, 'Aspirin');
      expect(response.rawText, 'BRUFEN Ibuprofen 400mg Aspirin');
    });

    test('parses response with empty drugs list', () {
      final json = {
        'drugs': <Map<String, dynamic>>[],
        'raw_text': 'some unrecognizable text',
      };

      final response = AnalyzeResponse.fromJson(json);

      expect(response.drugs, isEmpty);
      expect(response.rawText, 'some unrecognizable text');
    });

    test('maps raw_text snake_case key to rawText camelCase', () {
      final json = {
        'drugs': <Map<String, dynamic>>[],
        'raw_text': 'test',
      };

      final response = AnalyzeResponse.fromJson(json);
      expect(response.rawText, 'test');
    });
  });
}
