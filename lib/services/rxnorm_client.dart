import 'package:dio/dio.dart';

class RxNormClient {
  final Dio _dio;

  RxNormClient()
      : _dio = Dio(BaseOptions(
          baseUrl: 'https://rxnav.nlm.nih.gov/REST',
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ));

  /// Returns drug name suggestions for autocomplete.
  /// Uses approximateTerm to find rxcui matches, then resolves names.
  Future<List<String>> suggest(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      final response = await _dio.get('/approximateTerm.json', queryParameters: {
        'term': query,
        'maxEntries': 5,
      });

      final data = response.data as Map<String, dynamic>;
      final group = data['approximateGroup'] as Map<String, dynamic>?;
      final candidates = group?['candidate'] as List?;

      if (candidates == null || candidates.isEmpty) return [];

      // Extract unique rxcui values
      final rxcuis = candidates
          .map((c) => (c as Map<String, dynamic>)['rxcui'] as String?)
          .where((id) => id != null)
          .cast<String>()
          .toSet();

      // Resolve all rxcui values to drug names in parallel
      final resolved = await Future.wait(rxcuis.map(_resolveName));
      return resolved.whereType<String>().toList();
    } catch (_) {
      return [];
    }
  }

  Future<String?> _resolveName(String rxcui) async {
    try {
      final response = await _dio.get('/rxcui/$rxcui/properties.json');
      final data = response.data as Map<String, dynamic>;
      final props = data['properties'] as Map<String, dynamic>?;
      return props?['name'] as String?;
    } catch (_) {
      return null;
    }
  }
}
