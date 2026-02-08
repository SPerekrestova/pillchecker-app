import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pillchecker_app/main.dart';

void main() {
  testWidgets('App renders PillChecker title', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: PillCheckerApp()));

    expect(find.text('PillChecker'), findsOneWidget);
  });
}
