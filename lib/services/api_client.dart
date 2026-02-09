import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../models/analyze_response.dart';
import '../models/interactions_response.dart';

class ApiException implements Exception {
  final String message;
  const ApiException(this.message);

  @override
  String toString() => message;
}

class ApiClient {
  final Dio _dio;

  /// Creates an API client. When [dio] is provided (e.g. for testing),
  /// [baseUrl] is ignored — the injected instance's own config is used.
  ApiClient({String baseUrl = 'http://localhost:8000', Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: baseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 30),
            )) {
    if (kDebugMode && dio == null) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (msg) => debugPrint(msg.toString()),
      ));
    }
  }

  Future<AnalyzeResponse> analyze(String text) async {
    try {
      debugPrint('[API] POST /analyze  body: ${{'text': text}}');
      final response = await _dio.post('/analyze', data: {'text': text});
      debugPrint('[API] /analyze  status: ${response.statusCode}  body: ${response.data}');
      return AnalyzeResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      debugPrint('[API] /analyze  ERROR: ${e.type} ${e.message}');
      throw ApiException(_messageFromDioError(e));
    }
  }

  Future<InteractionsResponse> checkInteractions(List<String> drugs) async {
    try {
      debugPrint('[API] POST /interactions  body: ${{'drugs': drugs}}');
      final response =
          await _dio.post('/interactions', data: {'drugs': drugs});
      debugPrint('[API] /interactions  status: ${response.statusCode}  body: ${response.data}');
      return InteractionsResponse.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      debugPrint('[API] /interactions  ERROR: ${e.type} ${e.message}');
      throw ApiException(_messageFromDioError(e));
    }
  }

  String _messageFromDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timed out. Check your network.';
      case DioExceptionType.connectionError:
        return "Can't reach server. Check your connection.";
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        if (statusCode == 422) {
          return 'Invalid request. Please try again.';
        }
        return 'Server error ($statusCode). Please try again.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}
