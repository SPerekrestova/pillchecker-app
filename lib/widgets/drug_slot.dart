import 'package:flutter/material.dart';

class DrugSlotWidget extends StatelessWidget {
  final int slotIndex;
  final String? drugName;
  final VoidCallback onScan;
  final VoidCallback onType;
  final VoidCallback? onClear;

  const DrugSlotWidget({
    super.key,
    required this.slotIndex,
    this.drugName,
    required this.onScan,
    required this.onType,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final isFilled = drugName != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Drug ${slotIndex + 1}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (isFilled) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      drugName!,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                  if (onClear != null)
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: onClear,
                    ),
                ],
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onScan,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Scan'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onType,
                      icon: const Icon(Icons.keyboard),
                      label: const Text('Type'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
