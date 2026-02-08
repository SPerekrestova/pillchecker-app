import 'drug_result.dart';

class AnalyzeResponse {
  final List<DrugResult> drugs;
  final String rawText;

  const AnalyzeResponse({
    required this.drugs,
    required this.rawText,
  });

  factory AnalyzeResponse.fromJson(Map<String, dynamic> json) {
    return AnalyzeResponse(
      drugs: (json['drugs'] as List)
          .map((e) => DrugResult.fromJson(e as Map<String, dynamic>))
          .toList(),
      rawText: json['raw_text'] as String,
    );
  }
}
