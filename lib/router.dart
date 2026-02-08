import 'package:go_router/go_router.dart';
import 'screens/drug_input_screen.dart';
import 'screens/confirm_screen.dart';
import 'screens/results_screen.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const DrugInputScreen(),
    ),
    GoRoute(
      path: '/confirm',
      builder: (context, state) => const ConfirmScreen(),
    ),
    GoRoute(
      path: '/results',
      builder: (context, state) => const ResultsScreen(),
    ),
  ],
);
