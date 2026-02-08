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
      verify(() => mockDio.post('/analyze', data: {'text': 'Ibuprofen 400mg'}))
          .called(1);
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

    test('throws ApiException on send timeout', () async {
      when(() => mockDio.post('/analyze', data: any(named: 'data')))
          .thenThrow(DioException(
        type: DioExceptionType.sendTimeout,
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

    test('throws ApiException on receive timeout', () async {
      when(() => mockDio.post('/analyze', data: any(named: 'data')))
          .thenThrow(DioException(
        type: DioExceptionType.receiveTimeout,
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

    test('throws ApiException with generic message on unknown error', () async {
      when(() => mockDio.post('/analyze', data: any(named: 'data')))
          .thenThrow(DioException(
        type: DioExceptionType.cancel,
        requestOptions: RequestOptions(path: '/analyze'),
      ));

      expect(
        () => apiClient.analyze('test'),
        throwsA(isA<ApiException>().having(
          (e) => e.message,
          'message',
          contains('Something went wrong'),
        )),
      );
    });

    test('throws ApiException with validation message on 422', () async {
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
              data: {'drugs': ['ibuprofen', 'warfarin']}))
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
      verify(() => mockDio.post('/interactions',
              data: {'drugs': ['ibuprofen', 'warfarin']}))
          .called(1);
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
      verify(() => mockDio.post('/interactions', data: any(named: 'data')))
          .called(1);
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
