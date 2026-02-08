import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pillchecker_app/widgets/drug_slot.dart';

void main() {
  group('DrugSlotWidget', () {
    testWidgets('shows "Drug 1" for slotIndex 0', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: DrugSlotWidget(slotIndex: 0, onScan: () {}, onType: () {}),
        ),
      ));
      expect(find.text('Drug 1'), findsOneWidget);
    });

    testWidgets('shows "Drug 2" for slotIndex 1', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: DrugSlotWidget(slotIndex: 1, onScan: () {}, onType: () {}),
        ),
      ));
      expect(find.text('Drug 2'), findsOneWidget);
    });

    testWidgets('shows Scan and Type buttons when empty', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: DrugSlotWidget(slotIndex: 0, onScan: () {}, onType: () {}),
        ),
      ));
      expect(find.text('Scan'), findsOneWidget);
      expect(find.text('Type'), findsOneWidget);
    });

    testWidgets('shows drug name and hides buttons when filled', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: DrugSlotWidget(
            slotIndex: 0,
            drugName: 'Ibuprofen',
            onScan: () {},
            onType: () {},
          ),
        ),
      ));
      expect(find.text('Ibuprofen'), findsOneWidget);
      expect(find.text('Scan'), findsNothing);
      expect(find.text('Type'), findsNothing);
    });

    testWidgets('shows close button when onClear provided and filled', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: DrugSlotWidget(
            slotIndex: 0,
            drugName: 'Ibuprofen',
            onScan: () {},
            onType: () {},
            onClear: () {},
          ),
        ),
      ));
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('hides close button when onClear is null', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: DrugSlotWidget(
            slotIndex: 0,
            drugName: 'Ibuprofen',
            onScan: () {},
            onType: () {},
          ),
        ),
      ));
      expect(find.byIcon(Icons.close), findsNothing);
    });

    testWidgets('Scan button calls onScan', (tester) async {
      var called = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: DrugSlotWidget(
            slotIndex: 0,
            onScan: () => called = true,
            onType: () {},
          ),
        ),
      ));
      await tester.tap(find.text('Scan'));
      expect(called, isTrue);
    });

    testWidgets('Type button calls onType', (tester) async {
      var called = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: DrugSlotWidget(
            slotIndex: 0,
            onScan: () {},
            onType: () => called = true,
          ),
        ),
      ));
      await tester.tap(find.text('Type'));
      expect(called, isTrue);
    });

    testWidgets('close button calls onClear', (tester) async {
      var called = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: DrugSlotWidget(
            slotIndex: 0,
            drugName: 'Ibuprofen',
            onScan: () {},
            onType: () {},
            onClear: () => called = true,
          ),
        ),
      ));
      await tester.tap(find.byIcon(Icons.close));
      expect(called, isTrue);
    });
  });
}
