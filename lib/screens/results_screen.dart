import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/interaction_result.dart';
import '../providers/providers.dart';

class ResultsScreen extends ConsumerWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(interactionsResultProvider);

    if (result == null) {
      // Navigated here without data — go back
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Results')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (result.safe) ...[
                const _SafeCard(),
              ] else ...[
                Expanded(
                  child: ListView.separated(
                    itemCount: result.interactions.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _InteractionCard(
                        interaction: result.interactions[index],
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {
                  ref.read(drugSlotsProvider.notifier).reset();
                  ref.read(interactionsResultProvider.notifier).clear();
                  context.go('/');
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
                child: const Text('Start Over'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SafeCard extends StatelessWidget {
  const _SafeCard();

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              size: 80,
              color: Colors.green.shade600,
            ),
            const SizedBox(height: 16),
            Text(
              'No known interactions found',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.green.shade700,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _InteractionCard extends StatelessWidget {
  final InteractionResult interaction;

  const _InteractionCard({required this.interaction});

  Color _severityColor() {
    switch (interaction.severity.toLowerCase()) {
      case 'major':
        return Colors.red;
      case 'moderate':
        return Colors.orange;
      case 'minor':
        return Colors.yellow.shade700;
      default:
        return Colors.grey;
    }
  }

  IconData _severityIcon() {
    switch (interaction.severity.toLowerCase()) {
      case 'major':
        return Icons.dangerous;
      case 'moderate':
        return Icons.warning;
      case 'minor':
        return Icons.info;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _severityColor();

    return Card(
      shape: RoundedRectangleBorder(
        side: BorderSide(color: color, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_severityIcon(), color: color),
                const SizedBox(width: 8),
                Text(
                  interaction.severity.toUpperCase(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${interaction.drugA} + ${interaction.drugB}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Text(interaction.description),
            if (interaction.management.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Management: ${interaction.management}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
