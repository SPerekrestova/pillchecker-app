import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/drug_result.dart';
import '../models/interactions_response.dart';
import '../services/api_client.dart';
import '../services/ocr_service.dart';
import '../services/rxnorm_client.dart';

// --- Service providers ---

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

final rxNormClientProvider = Provider<RxNormClient>((ref) {
  return RxNormClient();
});

final ocrServiceProvider = Provider<OcrService>((ref) {
  final service = OcrService();
  ref.onDispose(service.dispose);
  return service;
});

// --- Drug slots state ---

class DrugSlot {
  final DrugResult? drug;
  final String? manualName;

  const DrugSlot({this.drug, this.manualName});

  String? get displayName => drug?.name ?? manualName;
  bool get isFilled => displayName != null;

  DrugSlot clear() => const DrugSlot();
}

class DrugSlotsNotifier extends Notifier<List<DrugSlot>> {
  @override
  List<DrugSlot> build() => [const DrugSlot(), const DrugSlot()];

  void setDrug(int index, DrugResult drug) {
    final updated = [...state];
    updated[index] = DrugSlot(drug: drug);
    state = updated;
  }

  void setManualName(int index, String name) {
    final updated = [...state];
    updated[index] = DrugSlot(manualName: name);
    state = updated;
  }

  void clearSlot(int index) {
    final updated = [...state];
    updated[index] = const DrugSlot();
    state = updated;
  }

  void reset() {
    state = [const DrugSlot(), const DrugSlot()];
  }

  bool get bothFilled => state.every((slot) => slot.isFilled);

  List<String> get drugNames =>
      state.map((s) => s.displayName).whereType<String>().toList();
}

final drugSlotsProvider =
    NotifierProvider<DrugSlotsNotifier, List<DrugSlot>>(
  DrugSlotsNotifier.new,
);

// --- Interactions result (set after API call) ---

class InteractionsResultNotifier extends Notifier<InteractionsResponse?> {
  @override
  InteractionsResponse? build() => null;

  void set(InteractionsResponse result) => state = result;
  void clear() => state = null;
}

final interactionsResultProvider =
    NotifierProvider<InteractionsResultNotifier, InteractionsResponse?>(
  InteractionsResultNotifier.new,
);
