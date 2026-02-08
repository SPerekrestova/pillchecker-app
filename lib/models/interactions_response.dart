import 'interaction_result.dart';

class InteractionsResponse {
  final List<InteractionResult> interactions;
  final bool safe;

  const InteractionsResponse({
    required this.interactions,
    required this.safe,
  });

  factory InteractionsResponse.fromJson(Map<String, dynamic> json) {
    return InteractionsResponse(
      interactions: (json['interactions'] as List)
          .map((e) => InteractionResult.fromJson(e as Map<String, dynamic>))
          .toList(),
      safe: json['safe'] as bool,
    );
  }
}
