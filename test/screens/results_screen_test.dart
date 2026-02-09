import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pillchecker_app/models/interaction_result.dart';
import 'package:pillchecker_app/models/interactions_response.dart';
import 'package:pillchecker_app/providers/providers.dart';
import 'package:pillchecker_app/screens/results_screen.dart';

class _TestInteractionsNotifier extends InteractionsResultNotifier {
  final InteractionsResponse? _initial;
  _TestInteractionsNotifier(this._initial);

  @override
  InteractionsResponse? build() => _initial;
}

void main() {
  Widget buildTestWidget({InteractionsResponse? result}) {
    final testRouter = GoRouter(
      initialLocation: '/results',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('Home')),
        ),
        GoRoute(
          path: '/results',
          builder: (_, _) => const ResultsScreen(),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        interactionsResultProvider
            .overrideWith(() => _TestInteractionsNotifier(result)),
        drugSlotsProvider.overrideWith(DrugSlotsNotifier.new),
      ],
      child: MaterialApp.router(routerConfig: testRouter),
    );
  }

  group('ResultsScreen', () {
    testWidgets('shows safe card when no interactions', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        result: InteractionsResponse(interactions: [], safe: true),
      ));
      await tester.pumpAndSettle();

      expect(find.text('No known interactions found'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('shows interaction cards when unsafe', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        result: InteractionsResponse(
          interactions: [
            InteractionResult(
              drugA: 'Ibuprofen',
              drugB: 'Warfarin',
              severity: 'Major',
              description: 'Increased bleeding risk',
              management: 'Avoid combination',
            ),
          ],
          safe: false,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('MAJOR'), findsOneWidget);
      expect(find.text('Ibuprofen + Warfarin'), findsOneWidget);
      expect(find.text('Increased bleeding risk'), findsOneWidget);
      expect(find.text('Management: Avoid combination'), findsOneWidget);
    });

    testWidgets('moderate severity shows warning icon', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        result: InteractionsResponse(
          interactions: [
            InteractionResult(
              drugA: 'A', drugB: 'B',
              severity: 'moderate', description: 'desc', management: '',
            ),
          ],
          safe: false,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('MODERATE'), findsOneWidget);
      expect(find.byIcon(Icons.warning), findsOneWidget);
    });

    testWidgets('hides management when empty', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        result: InteractionsResponse(
          interactions: [
            InteractionResult(
              drugA: 'A', drugB: 'B',
              severity: 'Minor', description: 'desc', management: '',
            ),
          ],
          safe: false,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('Management:'), findsNothing);
    });

    testWidgets('Start Over navigates to home', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        result: InteractionsResponse(interactions: [], safe: true),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Start Over'));
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('redirects to home when result is null', (tester) async {
      await tester.pumpWidget(buildTestWidget(result: null));
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
    });
  });
}
