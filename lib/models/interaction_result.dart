class InteractionResult {
  final String drugA;
  final String drugB;
  final String severity;
  final String description;
  final String management;

  const InteractionResult({
    required this.drugA,
    required this.drugB,
    required this.severity,
    required this.description,
    required this.management,
  });

  factory InteractionResult.fromJson(Map<String, dynamic> json) {
    return InteractionResult(
      drugA: json['drug_a'] as String,
      drugB: json['drug_b'] as String,
      severity: json['severity'] as String,
      description: json['description'] as String,
      management: json['management'] as String,
    );
  }
}
