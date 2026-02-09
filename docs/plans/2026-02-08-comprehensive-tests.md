# Comprehensive Test Suite Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add unit tests for models, services, and providers; widget tests for reusable components and screens — achieving coverage of all meaningful logic paths.

**Architecture:** Bottom-up testing — pure data models first (no mocks), then services (mock Dio), then providers (Riverpod container), then widgets (mock providers). Each task is independently verifiable.

**Tech Stack:** `flutter_test` (built-in), `mocktail` (mocking without codegen), `flutter_riverpod` (testing container)

---

### Task 0: Make services testable + add mocktail

`ApiClient` and `RxNormClient` both create `Dio` internally with no way to inject a mock. We need to add an optional `Dio` parameter to their constructors. This is the only production code change.

**Files:**
- Modify: `lib/services/api_client.dart:13-21`
- Modify: `lib/services/rxnorm_client.dart:3-11`
- Modify: `pubspec.yaml` (add `mocktail` dev dependency)

**Step 1: Add mocktail dev dependency**

Run: `flutter pub add --dev mocktail`

**Step 2: Make ApiClient accept optional Dio**

Replace the constructor at `lib/services/api_client.dart:13-21` with:

```dart
class ApiClient {
  final Dio _dio;

  ApiClient({String baseUrl = 'http://localhost:8000', Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: baseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 30),
            ));
```

**Step 3: Make RxNormClient accept optional Dio**

Replace the constructor at `lib/services/rxnorm_client.dart:3-11` with:

```dart
class RxNormClient {
  final Dio _dio;

  RxNormClient({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: 'https://rxnav.nlm.nih.gov/REST',
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            ));
```

**Step 4: Run checks**

Run: `flutter analyze` — Expected: No issues found
Run: `flutter test` — Expected: All tests passed

**Step 5: Commit**

```
feat: make ApiClient and RxNormClient testable via Dio injection
```

---

### Task 1: Model unit tests — DrugResult

**Files:**
- Create: `test/models/drug_result_test.dart`

**Step 1: Write the tests**

```dart
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

    test('handles confidence as int (num → double coercion)', () {
      final json = {
        'rxcui': null,
        'name': 'Test',
        'dosage': null,
        'form': null,
        'source': 'ner',
        'confidence': 1, // int, not double
      };

      final result = DrugResult.fromJson(json);

      expect(result.confidence, 1.0);
      expect(result.confidence, isA<double>());
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
```

**Step 2: Run test to verify it passes**

Run: `flutter test test/models/drug_result_test.dart -v`
Expected: All tests passed (5 tests)

**Step 3: Commit**

```
test: add DrugResult model unit tests
```

---

### Task 2: Model unit tests — AnalyzeResponse, InteractionResult, InteractionsResponse

**Files:**
- Create: `test/models/analyze_response_test.dart`
- Create: `test/models/interaction_result_test.dart`
- Create: `test/models/interactions_response_test.dart`

**Step 1: Write AnalyzeResponse tests**

```dart
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
```

**Step 2: Write InteractionResult tests**

```dart
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
```

**Step 3: Write InteractionsResponse tests**

```dart
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
```

**Step 4: Run all model tests**

Run: `flutter test test/models/ -v`
Expected: All tests passed (11 tests)

**Step 5: Commit**

```
test: add AnalyzeResponse, InteractionResult, InteractionsResponse model tests
```

---

### Task 3: Service unit tests — ApiClient

**Files:**
- Create: `test/services/api_client_test.dart`

**Step 1: Write the tests**

```dart
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pillchecker_app/services/api_client.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late ApiClient apiClient;

  setUp(() {
    mockDio = MockDio();
    apiClient = ApiClient(dio: mockDio);
  });

  group('analyze', () {
    test('sends text to /analyze and parses response', () async {
      when(() => mockDio.post('/analyze', data: {'text': 'Ibuprofen 400mg'}))
          .thenAnswer((_) async => Response(
                data: {
                  'drugs': [
                    {
                      'rxcui': '5640',
                      'name': 'Ibuprofen',
                      'dosage': '400mg',
                      'form': 'tablet',
                      'source': 'ner',
                      'confidence': 0.95,
                    }
                  ],
                  'raw_text': 'Ibuprofen 400mg',
                },
                statusCode: 200,
                requestOptions: RequestOptions(path: '/analyze'),
              ));

      final result = await apiClient.analyze('Ibuprofen 400mg');

      expect(result.drugs.length, 1);
      expect(result.drugs.first.name, 'Ibuprofen');
      expect(result.rawText, 'Ibuprofen 400mg');
    });

    test('throws ApiException on connection timeout', () async {
      when(() => mockDio.post('/analyze', data: any(named: 'data')))
          .thenThrow(DioException(
        type: DioExceptionType.connectionTimeout,
        requestOptions: RequestOptions(path: '/analyze'),
      ));

      expect(
        () => apiClient.analyze('test'),
        throwsA(isA<ApiException>().having(
          (e) => e.message,
          'message',
          contains('timed out'),
        )),
      );
    });

    test('throws ApiException on connection error', () async {
      when(() => mockDio.post('/analyze', data: any(named: 'data')))
          .thenThrow(DioException(
        type: DioExceptionType.connectionError,
        requestOptions: RequestOptions(path: '/analyze'),
      ));

      expect(
        () => apiClient.analyze('test'),
        throwsA(isA<ApiException>().having(
          (e) => e.message,
          'message',
          contains("Can't reach server"),
        )),
      );
    });

    test('throws ApiException with status code on 422', () async {
      when(() => mockDio.post('/analyze', data: any(named: 'data')))
          .thenThrow(DioException(
        type: DioExceptionType.badResponse,
        response: Response(
          statusCode: 422,
          requestOptions: RequestOptions(path: '/analyze'),
        ),
        requestOptions: RequestOptions(path: '/analyze'),
      ));

      expect(
        () => apiClient.analyze('test'),
        throwsA(isA<ApiException>().having(
          (e) => e.message,
          'message',
          contains('Invalid request'),
        )),
      );
    });

    test('throws ApiException with status code on 500', () async {
      when(() => mockDio.post('/analyze', data: any(named: 'data')))
          .thenThrow(DioException(
        type: DioExceptionType.badResponse,
        response: Response(
          statusCode: 500,
          requestOptions: RequestOptions(path: '/analyze'),
        ),
        requestOptions: RequestOptions(path: '/analyze'),
      ));

      expect(
        () => apiClient.analyze('test'),
        throwsA(isA<ApiException>().having(
          (e) => e.message,
          'message',
          contains('Server error (500)'),
        )),
      );
    });
  });

  group('checkInteractions', () {
    test('sends drug names and parses safe response', () async {
      when(() => mockDio.post('/interactions',
              data: {
                'drugs': ['ibuprofen', 'warfarin']
              }))
          .thenAnswer((_) async => Response(
                data: {
                  'interactions': <Map<String, dynamic>>[],
                  'safe': true,
                },
                statusCode: 200,
                requestOptions: RequestOptions(path: '/interactions'),
              ));

      final result =
          await apiClient.checkInteractions(['ibuprofen', 'warfarin']);

      expect(result.safe, isTrue);
      expect(result.interactions, isEmpty);
    });

    test('parses unsafe response with interactions', () async {
      when(() => mockDio.post('/interactions', data: any(named: 'data')))
          .thenAnswer((_) async => Response(
                data: {
                  'interactions': [
                    {
                      'drug_a': 'Ibuprofen',
                      'drug_b': 'Warfarin',
                      'severity': 'Major',
                      'description': 'Bleeding risk',
                      'management': 'Avoid',
                    }
                  ],
                  'safe': false,
                },
                statusCode: 200,
                requestOptions: RequestOptions(path: '/interactions'),
              ));

      final result =
          await apiClient.checkInteractions(['ibuprofen', 'warfarin']);

      expect(result.safe, isFalse);
      expect(result.interactions.length, 1);
      expect(result.interactions[0].severity, 'Major');
    });

    test('throws ApiException on connection error', () async {
      when(() => mockDio.post('/interactions', data: any(named: 'data')))
          .thenThrow(DioException(
        type: DioExceptionType.connectionError,
        requestOptions: RequestOptions(path: '/interactions'),
      ));

      expect(
        () => apiClient.checkInteractions(['a', 'b']),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('ApiException', () {
    test('toString returns message', () {
      const e = ApiException('test error');
      expect(e.toString(), 'test error');
    });
  });
}
```

**Step 2: Run tests**

Run: `flutter test test/services/api_client_test.dart -v`
Expected: All tests passed (9 tests)

**Step 3: Commit**

```
test: add ApiClient service unit tests with mocked Dio
```

---

### Task 4: Service unit tests — RxNormClient

**Files:**
- Create: `test/services/rxnorm_client_test.dart`

**Step 1: Write the tests**

```dart
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pillchecker_app/services/rxnorm_client.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late RxNormClient client;

  setUp(() {
    mockDio = MockDio();
    client = RxNormClient(dio: mockDio);
  });

  group('suggest', () {
    test('returns empty list for empty query', () async {
      final result = await client.suggest('');
      expect(result, isEmpty);
    });

    test('returns empty list for whitespace-only query', () async {
      final result = await client.suggest('   ');
      expect(result, isEmpty);
    });

    test('returns resolved drug names for valid query', () async {
      // Mock approximateTerm call
      when(() => mockDio.get('/approximateTerm.json',
              queryParameters: any(named: 'queryParameters')))
          .thenAnswer((_) async => Response(
                data: {
                  'approximateGroup': {
                    'candidate': [
                      {'rxcui': '5640', 'rxaui': '123', 'score': '100', 'rank': '1'},
                      {'rxcui': '1191', 'rxaui': '456', 'score': '80', 'rank': '2'},
                    ],
                  },
                },
                statusCode: 200,
                requestOptions: RequestOptions(path: '/approximateTerm.json'),
              ));

      // Mock name resolution calls
      when(() => mockDio.get('/rxcui/5640/properties.json'))
          .thenAnswer((_) async => Response(
                data: {
                  'properties': {'name': 'ibuprofen'},
                },
                statusCode: 200,
                requestOptions:
                    RequestOptions(path: '/rxcui/5640/properties.json'),
              ));
      when(() => mockDio.get('/rxcui/1191/properties.json'))
          .thenAnswer((_) async => Response(
                data: {
                  'properties': {'name': 'aspirin'},
                },
                statusCode: 200,
                requestOptions:
                    RequestOptions(path: '/rxcui/1191/properties.json'),
              ));

      final result = await client.suggest('ibup');

      expect(result, containsAll(['ibuprofen', 'aspirin']));
      expect(result.length, 2);
    });

    test('deduplicates rxcui values', () async {
      when(() => mockDio.get('/approximateTerm.json',
              queryParameters: any(named: 'queryParameters')))
          .thenAnswer((_) async => Response(
                data: {
                  'approximateGroup': {
                    'candidate': [
                      {'rxcui': '5640', 'rxaui': '123', 'score': '100', 'rank': '1'},
                      {'rxcui': '5640', 'rxaui': '789', 'score': '90', 'rank': '2'},
                    ],
                  },
                },
                statusCode: 200,
                requestOptions: RequestOptions(path: '/approximateTerm.json'),
              ));

      when(() => mockDio.get('/rxcui/5640/properties.json'))
          .thenAnswer((_) async => Response(
                data: {
                  'properties': {'name': 'ibuprofen'},
                },
                statusCode: 200,
                requestOptions:
                    RequestOptions(path: '/rxcui/5640/properties.json'),
              ));

      final result = await client.suggest('ibup');

      expect(result.length, 1);
      expect(result.first, 'ibuprofen');
    });

    test('returns empty list when no candidates', () async {
      when(() => mockDio.get('/approximateTerm.json',
              queryParameters: any(named: 'queryParameters')))
          .thenAnswer((_) async => Response(
                data: {
                  'approximateGroup': {
                    'candidate': <Map<String, dynamic>>[],
                  },
                },
                statusCode: 200,
                requestOptions: RequestOptions(path: '/approximateTerm.json'),
              ));

      final result = await client.suggest('zzzzzzz');
      expect(result, isEmpty);
    });

    test('returns empty list when approximateGroup is null', () async {
      when(() => mockDio.get('/approximateTerm.json',
              queryParameters: any(named: 'queryParameters')))
          .thenAnswer((_) async => Response(
                data: <String, dynamic>{},
                statusCode: 200,
                requestOptions: RequestOptions(path: '/approximateTerm.json'),
              ));

      final result = await client.suggest('test');
      expect(result, isEmpty);
    });

    test('returns empty list on network error', () async {
      when(() => mockDio.get('/approximateTerm.json',
              queryParameters: any(named: 'queryParameters')))
          .thenThrow(DioException(
        type: DioExceptionType.connectionError,
        requestOptions: RequestOptions(path: '/approximateTerm.json'),
      ));

      final result = await client.suggest('test');
      expect(result, isEmpty);
    });

    test('skips candidates where name resolution fails', () async {
      when(() => mockDio.get('/approximateTerm.json',
              queryParameters: any(named: 'queryParameters')))
          .thenAnswer((_) async => Response(
                data: {
                  'approximateGroup': {
                    'candidate': [
                      {'rxcui': '5640', 'rxaui': '123', 'score': '100', 'rank': '1'},
                      {'rxcui': '9999', 'rxaui': '456', 'score': '80', 'rank': '2'},
                    ],
                  },
                },
                statusCode: 200,
                requestOptions: RequestOptions(path: '/approximateTerm.json'),
              ));

      when(() => mockDio.get('/rxcui/5640/properties.json'))
          .thenAnswer((_) async => Response(
                data: {
                  'properties': {'name': 'ibuprofen'},
                },
                statusCode: 200,
                requestOptions:
                    RequestOptions(path: '/rxcui/5640/properties.json'),
              ));
      when(() => mockDio.get('/rxcui/9999/properties.json'))
          .thenThrow(DioException(
        type: DioExceptionType.connectionError,
        requestOptions: RequestOptions(path: '/rxcui/9999/properties.json'),
      ));

      final result = await client.suggest('test');

      expect(result.length, 1);
      expect(result.first, 'ibuprofen');
    });
  });
}
```

**Step 2: Run tests**

Run: `flutter test test/services/rxnorm_client_test.dart -v`
Expected: All tests passed (8 tests)

**Step 3: Commit**

```
test: add RxNormClient service unit tests with mocked Dio
```

---

### Task 5: Provider unit tests — DrugSlot, DrugSlotsNotifier, InteractionsResultNotifier

**Files:**
- Create: `test/providers/providers_test.dart`

**Step 1: Write the tests**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pillchecker_app/models/drug_result.dart';
import 'package:pillchecker_app/models/interaction_result.dart';
import 'package:pillchecker_app/models/interactions_response.dart';
import 'package:pillchecker_app/providers/providers.dart';

void main() {
  group('DrugSlot', () {
    test('displayName returns drug.name when drug is set', () {
      final slot = DrugSlot(
        drug: DrugResult(
          name: 'Ibuprofen',
          source: 'ner',
          confidence: 0.9,
        ),
      );
      expect(slot.displayName, 'Ibuprofen');
    });

    test('displayName returns manualName when no drug', () {
      const slot = DrugSlot(manualName: 'Aspirin');
      expect(slot.displayName, 'Aspirin');
    });

    test('displayName prefers drug.name over manualName', () {
      final slot = DrugSlot(
        drug: DrugResult(
          name: 'Ibuprofen',
          source: 'ner',
          confidence: 0.9,
        ),
        manualName: 'Aspirin',
      );
      expect(slot.displayName, 'Ibuprofen');
    });

    test('displayName is null when empty', () {
      const slot = DrugSlot();
      expect(slot.displayName, isNull);
    });

    test('isFilled is true when drug is set', () {
      final slot = DrugSlot(
        drug: DrugResult(
          name: 'Ibuprofen',
          source: 'ner',
          confidence: 0.9,
        ),
      );
      expect(slot.isFilled, isTrue);
    });

    test('isFilled is true when manualName is set', () {
      const slot = DrugSlot(manualName: 'Aspirin');
      expect(slot.isFilled, isTrue);
    });

    test('isFilled is false when empty', () {
      const slot = DrugSlot();
      expect(slot.isFilled, isFalse);
    });

    test('clear returns empty slot', () {
      final slot = DrugSlot(
        drug: DrugResult(
          name: 'Ibuprofen',
          source: 'ner',
          confidence: 0.9,
        ),
      );
      final cleared = slot.clear();
      expect(cleared.drug, isNull);
      expect(cleared.manualName, isNull);
      expect(cleared.isFilled, isFalse);
    });
  });

  group('DrugSlotsNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initializes with two empty slots', () {
      final slots = container.read(drugSlotsProvider);
      expect(slots.length, 2);
      expect(slots[0].isFilled, isFalse);
      expect(slots[1].isFilled, isFalse);
    });

    test('setDrug updates correct slot', () {
      final drug = DrugResult(
        name: 'Ibuprofen',
        source: 'ner',
        confidence: 0.9,
      );

      container.read(drugSlotsProvider.notifier).setDrug(0, drug);

      final slots = container.read(drugSlotsProvider);
      expect(slots[0].displayName, 'Ibuprofen');
      expect(slots[1].isFilled, isFalse);
    });

    test('setDrug on slot 1 does not affect slot 0', () {
      final drug = DrugResult(
        name: 'Aspirin',
        source: 'ner',
        confidence: 0.8,
      );

      container.read(drugSlotsProvider.notifier).setDrug(1, drug);

      final slots = container.read(drugSlotsProvider);
      expect(slots[0].isFilled, isFalse);
      expect(slots[1].displayName, 'Aspirin');
    });

    test('setManualName updates correct slot', () {
      container.read(drugSlotsProvider.notifier).setManualName(0, 'Ibuprofen');

      final slots = container.read(drugSlotsProvider);
      expect(slots[0].displayName, 'Ibuprofen');
      expect(slots[0].drug, isNull);
    });

    test('clearSlot empties the target slot', () {
      container.read(drugSlotsProvider.notifier).setManualName(0, 'Ibuprofen');
      container.read(drugSlotsProvider.notifier).clearSlot(0);

      final slots = container.read(drugSlotsProvider);
      expect(slots[0].isFilled, isFalse);
    });

    test('reset clears all slots', () {
      container.read(drugSlotsProvider.notifier).setManualName(0, 'Ibuprofen');
      container.read(drugSlotsProvider.notifier).setManualName(1, 'Aspirin');
      container.read(drugSlotsProvider.notifier).reset();

      final slots = container.read(drugSlotsProvider);
      expect(slots[0].isFilled, isFalse);
      expect(slots[1].isFilled, isFalse);
    });

    test('bothFilled is true when both slots filled', () {
      container.read(drugSlotsProvider.notifier).setManualName(0, 'Ibuprofen');
      container.read(drugSlotsProvider.notifier).setManualName(1, 'Aspirin');

      expect(
          container.read(drugSlotsProvider.notifier).bothFilled, isTrue);
    });

    test('bothFilled is false when one slot empty', () {
      container.read(drugSlotsProvider.notifier).setManualName(0, 'Ibuprofen');

      expect(
          container.read(drugSlotsProvider.notifier).bothFilled, isFalse);
    });

    test('drugNames returns filled names in order', () {
      container.read(drugSlotsProvider.notifier).setManualName(0, 'Ibuprofen');
      container.read(drugSlotsProvider.notifier).setManualName(1, 'Aspirin');

      expect(container.read(drugSlotsProvider.notifier).drugNames,
          ['Ibuprofen', 'Aspirin']);
    });

    test('drugNames skips empty slots', () {
      container.read(drugSlotsProvider.notifier).setManualName(1, 'Aspirin');

      expect(
          container.read(drugSlotsProvider.notifier).drugNames, ['Aspirin']);
    });
  });

  group('InteractionsResultNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initializes as null', () {
      expect(container.read(interactionsResultProvider), isNull);
    });

    test('set stores result', () {
      final response = InteractionsResponse(
        interactions: [
          InteractionResult(
            drugA: 'A',
            drugB: 'B',
            severity: 'Major',
            description: 'desc',
            management: 'mgmt',
          ),
        ],
        safe: false,
      );

      container.read(interactionsResultProvider.notifier).set(response);

      expect(container.read(interactionsResultProvider), isNotNull);
      expect(container.read(interactionsResultProvider)!.safe, isFalse);
    });

    test('clear resets to null', () {
      final response = InteractionsResponse(
        interactions: [],
        safe: true,
      );

      container.read(interactionsResultProvider.notifier).set(response);
      container.read(interactionsResultProvider.notifier).clear();

      expect(container.read(interactionsResultProvider), isNull);
    });
  });
}
```

**Step 2: Run tests**

Run: `flutter test test/providers/providers_test.dart -v`
Expected: All tests passed (19 tests)

**Step 3: Commit**

```
test: add DrugSlot, DrugSlotsNotifier, InteractionsResultNotifier provider tests
```

---

### Task 6: Widget test — DrugSlotWidget

**Files:**
- Create: `test/widgets/drug_slot_test.dart`

**Step 1: Write the tests**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pillchecker_app/widgets/drug_slot.dart';

void main() {
  group('DrugSlotWidget', () {
    testWidgets('shows "Drug 1" for slotIndex 0', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: DrugSlotWidget(
            slotIndex: 0,
            onScan: () {},
            onType: () {},
          ),
        ),
      ));

      expect(find.text('Drug 1'), findsOneWidget);
    });

    testWidgets('shows "Drug 2" for slotIndex 1', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: DrugSlotWidget(
            slotIndex: 1,
            onScan: () {},
            onType: () {},
          ),
        ),
      ));

      expect(find.text('Drug 2'), findsOneWidget);
    });

    testWidgets('shows Scan and Type buttons when empty', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: DrugSlotWidget(
            slotIndex: 0,
            onScan: () {},
            onType: () {},
          ),
        ),
      ));

      expect(find.text('Scan'), findsOneWidget);
      expect(find.text('Type'), findsOneWidget);
    });

    testWidgets('shows drug name when filled', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: DrugSlotWidget(
            slotIndex: 0,
            drugName: 'Ibuprofen',
            onScan: () {},
            onType: () {},
          ),
        ),
      ));

      expect(find.text('Ibuprofen'), findsOneWidget);
      expect(find.text('Scan'), findsNothing);
      expect(find.text('Type'), findsNothing);
    });

    testWidgets('shows close button when onClear provided and filled',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: DrugSlotWidget(
            slotIndex: 0,
            drugName: 'Ibuprofen',
            onScan: () {},
            onType: () {},
            onClear: () {},
          ),
        ),
      ));

      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('hides close button when onClear is null', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: DrugSlotWidget(
            slotIndex: 0,
            drugName: 'Ibuprofen',
            onScan: () {},
            onType: () {},
          ),
        ),
      ));

      expect(find.byIcon(Icons.close), findsNothing);
    });

    testWidgets('Scan button calls onScan', (tester) async {
      var scanCalled = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: DrugSlotWidget(
            slotIndex: 0,
            onScan: () => scanCalled = true,
            onType: () {},
          ),
        ),
      ));

      await tester.tap(find.text('Scan'));
      expect(scanCalled, isTrue);
    });

    testWidgets('Type button calls onType', (tester) async {
      var typeCalled = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: DrugSlotWidget(
            slotIndex: 0,
            onScan: () {},
            onType: () => typeCalled = true,
          ),
        ),
      ));

      await tester.tap(find.text('Type'));
      expect(typeCalled, isTrue);
    });

    testWidgets('close button calls onClear', (tester) async {
      var clearCalled = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: DrugSlotWidget(
            slotIndex: 0,
            drugName: 'Ibuprofen',
            onScan: () {},
            onType: () {},
            onClear: () => clearCalled = true,
          ),
        ),
      ));

      await tester.tap(find.byIcon(Icons.close));
      expect(clearCalled, isTrue);
    });
  });
}
```

**Step 2: Run tests**

Run: `flutter test test/widgets/drug_slot_test.dart -v`
Expected: All tests passed (9 tests)

**Step 3: Commit**

```
test: add DrugSlotWidget widget tests
```

---

### Task 7: Widget test — ResultsScreen

Tests the results screen with mocked Riverpod providers (safe + unsafe + redirect scenarios).

**Files:**
- Create: `test/screens/results_screen_test.dart`

**Step 1: Write the tests**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pillchecker_app/models/interaction_result.dart';
import 'package:pillchecker_app/models/interactions_response.dart';
import 'package:pillchecker_app/providers/providers.dart';
import 'package:pillchecker_app/screens/results_screen.dart';

void main() {
  Widget buildTestWidget({InteractionsResponse? result}) {
    final router = GoRouter(
      initialLocation: '/results',
      routes: [
        GoRoute(path: '/', builder: (_, _) => const Scaffold(body: Text('Home'))),
        GoRoute(
            path: '/results', builder: (_, _) => const ResultsScreen()),
      ],
    );

    return ProviderScope(
      overrides: [
        interactionsResultProvider
            .overrideWith(() => _TestInteractionsNotifier(result)),
        drugSlotsProvider.overrideWith(() => DrugSlotsNotifier()),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  group('ResultsScreen', () {
    testWidgets('shows safe card when no interactions', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        result: InteractionsResponse(interactions: [], safe: true),
      ));
      await tester.pumpAndSettle();

      expect(find.text('No known interactions found'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('shows interaction cards when unsafe', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        result: InteractionsResponse(
          interactions: [
            InteractionResult(
              drugA: 'Ibuprofen',
              drugB: 'Warfarin',
              severity: 'Major',
              description: 'Increased bleeding risk',
              management: 'Avoid combination',
            ),
          ],
          safe: false,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('MAJOR'), findsOneWidget);
      expect(find.text('Ibuprofen + Warfarin'), findsOneWidget);
      expect(find.text('Increased bleeding risk'), findsOneWidget);
      expect(find.text('Management: Avoid combination'), findsOneWidget);
    });

    testWidgets('severity colors map correctly', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        result: InteractionsResponse(
          interactions: [
            InteractionResult(
              drugA: 'A',
              drugB: 'B',
              severity: 'moderate',
              description: 'desc',
              management: '',
            ),
          ],
          safe: false,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('MODERATE'), findsOneWidget);
      expect(find.byIcon(Icons.warning), findsOneWidget);
    });

    testWidgets('hides management when empty', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        result: InteractionsResponse(
          interactions: [
            InteractionResult(
              drugA: 'A',
              drugB: 'B',
              severity: 'Minor',
              description: 'desc',
              management: '',
            ),
          ],
          safe: false,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('Management:'), findsNothing);
    });

    testWidgets('Start Over button navigates to home', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        result: InteractionsResponse(interactions: [], safe: true),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Start Over'));
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('redirects to home when result is null', (tester) async {
      await tester.pumpWidget(buildTestWidget(result: null));
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
    });
  });
}

class _TestInteractionsNotifier extends InteractionsResultNotifier {
  final InteractionsResponse? _initial;
  _TestInteractionsNotifier(this._initial);

  @override
  InteractionsResponse? build() => _initial;
}
```

**Step 2: Run tests**

Run: `flutter test test/screens/results_screen_test.dart -v`
Expected: All tests passed (6 tests)

**Step 3: Commit**

```
test: add ResultsScreen widget tests with mocked providers
```

---

### Task 8: Final verification — run full suite

**Step 1: Run all tests**

Run: `flutter test -v`
Expected: All tests passed (57+ tests across 7 files)

**Step 2: Run analysis**

Run: `flutter analyze`
Expected: No issues found

**Step 3: Commit (if any fixups needed)**

**Step 4: Request code review**

Use `superpowers:requesting-code-review` to validate the full test suite.

---

## Test File Summary

```
test/
├── models/
│   ├── drug_result_test.dart              (5 tests)
│   ├── analyze_response_test.dart         (3 tests)
│   ├── interaction_result_test.dart       (3 tests)
│   └── interactions_response_test.dart    (3 tests)
├── services/
│   ├── api_client_test.dart               (9 tests)
│   └── rxnorm_client_test.dart            (8 tests)
├── providers/
│   └── providers_test.dart                (19 tests)
├── widgets/
│   └── drug_slot_test.dart                (9 tests)
├── screens/
│   └── results_screen_test.dart           (6 tests)
└── widget_test.dart                       (1 test — existing)
```

**Total: ~66 tests** covering models (JSON parsing, round-trips), services (API calls, error handling, mocked Dio), providers (state transitions, Riverpod container), widgets (rendering, callbacks), and screens (navigation, provider integration).
