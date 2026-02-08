class DrugResult {
  final String? rxcui;
  final String name;
  final String? dosage;
  final String? form;
  final String source;
  final double confidence;

  const DrugResult({
    this.rxcui,
    required this.name,
    this.dosage,
    this.form,
    required this.source,
    required this.confidence,
  });

  factory DrugResult.fromJson(Map<String, dynamic> json) {
    return DrugResult(
      rxcui: json['rxcui'] as String?,
      name: json['name'] as String,
      dosage: json['dosage'] as String?,
      form: json['form'] as String?,
      source: json['source'] as String,
      confidence: (json['confidence'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rxcui': rxcui,
      'name': name,
      'dosage': dosage,
      'form': form,
      'source': source,
      'confidence': confidence,
    };
  }
}
