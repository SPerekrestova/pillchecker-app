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

      when(() => mockDio.get('/rxcui/5640/properties.json'))
          .thenAnswer((_) async => Response(
                data: {'properties': {'name': 'ibuprofen'}},
                statusCode: 200,
                requestOptions: RequestOptions(path: '/rxcui/5640/properties.json'),
              ));
      when(() => mockDio.get('/rxcui/1191/properties.json'))
          .thenAnswer((_) async => Response(
                data: {'properties': {'name': 'aspirin'}},
                statusCode: 200,
                requestOptions: RequestOptions(path: '/rxcui/1191/properties.json'),
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
                data: {'properties': {'name': 'ibuprofen'}},
                statusCode: 200,
                requestOptions: RequestOptions(path: '/rxcui/5640/properties.json'),
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
                data: {'properties': {'name': 'ibuprofen'}},
                statusCode: 200,
                requestOptions: RequestOptions(path: '/rxcui/5640/properties.json'),
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
