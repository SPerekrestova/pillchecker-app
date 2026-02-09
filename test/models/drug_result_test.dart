import 'package:flutter_test/flutter_test.dart';
import 'package:pillchecker_app/models/drug_result.dart';

void main() {
  group('DrugResult.fromJson', () {
    test('parses all fields correctly', () {
      final json = {
        'rxcui': '5640',
        'name': 'Ibuprofen',
        'dosage': '400mg',
        'form': 'tablet',
        'source': 'ner',
        'confidence': 0.95,
      };

      final result = DrugResult.fromJson(json);

      expect(result.rxcui, '5640');
      expect(result.name, 'Ibuprofen');
      expect(result.dosage, '400mg');
      expect(result.form, 'tablet');
      expect(result.source, 'ner');
      expect(result.confidence, 0.95);
    });

    test('handles null optional fields', () {
      final json = {
        'rxcui': null,
        'name': 'Aspirin',
        'dosage': null,
        'form': null,
        'source': 'rxnorm_fallback',
        'confidence': 0.8,
      };

      final result = DrugResult.fromJson(json);

      expect(result.rxcui, isNull);
      expect(result.name, 'Aspirin');
      expect(result.dosage, isNull);
      expect(result.form, isNull);
    });

    test('handles confidence as int (num to double coercion)', () {
      final json = {
        'rxcui': null,
        'name': 'Test',
        'dosage': null,
        'form': null,
        'source': 'ner',
        'confidence': 1,
      };

      final result = DrugResult.fromJson(json);

      expect(result.confidence, 1.0);
      expect(result.confidence, isA<double>());
    });

    test('throws when required field "name" is missing', () {
      final json = {
        'source': 'ner',
        'confidence': 0.9,
      };
      expect(() => DrugResult.fromJson(json), throwsA(isA<TypeError>()));
    });

    test('throws when required field "source" is missing', () {
      final json = {
        'name': 'Test',
        'confidence': 0.9,
      };
      expect(() => DrugResult.fromJson(json), throwsA(isA<TypeError>()));
    });

    test('throws when required field "confidence" is missing', () {
      final json = {
        'name': 'Test',
        'source': 'ner',
      };
      expect(() => DrugResult.fromJson(json), throwsA(isA<TypeError>()));
    });
  });

  group('DrugResult.toJson', () {
    test('round-trips through fromJson', () {
      final original = DrugResult(
        rxcui: '5640',
        name: 'Ibuprofen',
        dosage: '400mg',
        form: 'tablet',
        source: 'ner',
        confidence: 0.95,
      );

      final json = original.toJson();
      final restored = DrugResult.fromJson(json);

      expect(restored.rxcui, original.rxcui);
      expect(restored.name, original.name);
      expect(restored.dosage, original.dosage);
      expect(restored.form, original.form);
      expect(restored.source, original.source);
      expect(restored.confidence, original.confidence);
    });

    test('includes null values in output', () {
      final result = DrugResult(
        name: 'Test',
        source: 'ner',
        confidence: 0.5,
      );

      final json = result.toJson();

      expect(json.containsKey('rxcui'), isTrue);
      expect(json['rxcui'], isNull);
    });
  });
}
