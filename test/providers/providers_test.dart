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
        drug: DrugResult(name: 'Ibuprofen', source: 'ner', confidence: 0.9),
      );
      expect(slot.displayName, 'Ibuprofen');
    });

    test('displayName returns manualName when no drug', () {
      const slot = DrugSlot(manualName: 'Aspirin');
      expect(slot.displayName, 'Aspirin');
    });

    test('displayName prefers drug.name over manualName', () {
      final slot = DrugSlot(
        drug: DrugResult(name: 'Ibuprofen', source: 'ner', confidence: 0.9),
        manualName: 'Aspirin',
      );
      expect(slot.displayName, 'Ibuprofen');
    });

    test('displayName is null when empty', () {
      const slot = DrugSlot();
      expect(slot.displayName, isNull);
    });

    test('displayName is null for empty-string manualName', () {
      const slot = DrugSlot(manualName: '');
      expect(slot.displayName, isNull);
      expect(slot.isFilled, isFalse);
    });

    test('displayName is null for whitespace-only manualName', () {
      const slot = DrugSlot(manualName: '   ');
      expect(slot.displayName, isNull);
      expect(slot.isFilled, isFalse);
    });

    test('isFilled is true when drug is set', () {
      final slot = DrugSlot(
        drug: DrugResult(name: 'Ibuprofen', source: 'ner', confidence: 0.9),
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
        drug: DrugResult(name: 'Ibuprofen', source: 'ner', confidence: 0.9),
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

    test('setDrug updates correct slot without affecting other', () {
      final drug = DrugResult(name: 'Ibuprofen', source: 'ner', confidence: 0.9);

      container.read(drugSlotsProvider.notifier).setDrug(0, drug);

      final slots = container.read(drugSlotsProvider);
      expect(slots[0].displayName, 'Ibuprofen');
      expect(slots[1].isFilled, isFalse);
    });

    test('setDrug on slot 1 does not affect slot 0', () {
      final drug = DrugResult(name: 'Aspirin', source: 'ner', confidence: 0.8);

      container.read(drugSlotsProvider.notifier).setDrug(1, drug);

      final slots = container.read(drugSlotsProvider);
      expect(slots[0].isFilled, isFalse);
      expect(slots[1].displayName, 'Aspirin');
    });

    test('setManualName updates correct slot with no drug data', () {
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

      expect(container.read(drugSlotsProvider.notifier).bothFilled, isTrue);
    });

    test('bothFilled is false when one slot empty', () {
      container.read(drugSlotsProvider.notifier).setManualName(0, 'Ibuprofen');

      expect(container.read(drugSlotsProvider.notifier).bothFilled, isFalse);
    });

    test('drugNames returns filled names in order', () {
      container.read(drugSlotsProvider.notifier).setManualName(0, 'Ibuprofen');
      container.read(drugSlotsProvider.notifier).setManualName(1, 'Aspirin');

      expect(container.read(drugSlotsProvider.notifier).drugNames,
          ['Ibuprofen', 'Aspirin']);
    });

    test('drugNames skips empty slots', () {
      container.read(drugSlotsProvider.notifier).setManualName(1, 'Aspirin');

      expect(container.read(drugSlotsProvider.notifier).drugNames, ['Aspirin']);
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
            drugA: 'A', drugB: 'B',
            severity: 'Major', description: 'desc', management: 'mgmt',
          ),
        ],
        safe: false,
      );

      container.read(interactionsResultProvider.notifier).set(response);

      expect(container.read(interactionsResultProvider), isNotNull);
      expect(container.read(interactionsResultProvider)!.safe, isFalse);
    });

    test('clear resets to null', () {
      final response = InteractionsResponse(interactions: [], safe: true);

      container.read(interactionsResultProvider.notifier).set(response);
      container.read(interactionsResultProvider.notifier).clear();

      expect(container.read(interactionsResultProvider), isNull);
    });
  });
}
