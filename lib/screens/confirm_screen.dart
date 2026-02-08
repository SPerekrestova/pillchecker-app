import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/providers.dart';
import '../services/api_client.dart';
import '../services/rxnorm_client.dart';

class ConfirmScreen extends ConsumerStatefulWidget {
  const ConfirmScreen({super.key});

  @override
  ConsumerState<ConfirmScreen> createState() => _ConfirmScreenState();
}

class _ConfirmScreenState extends ConsumerState<ConfirmScreen> {
  bool _isLoading = false;
  String? _error;
  int? _editingIndex;

  Future<void> _checkInteractions() async {
    final notifier = ref.read(drugSlotsProvider.notifier);
    if (!notifier.bothFilled) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      final result = await apiClient.checkInteractions(notifier.drugNames);
      if (!mounted) return;
      ref.read(interactionsResultProvider.notifier).set(result);
      context.go('/results');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final slots = ref.watch(drugSlotsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Confirm Drugs')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Card(
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _error!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onErrorContainer,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: _checkInteractions,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              for (var i = 0; i < slots.length; i++) ...[
                _DrugConfirmCard(
                  index: i,
                  slot: slots[i],
                  isEditing: _editingIndex == i,
                  onStartEdit: () => setState(() => _editingIndex = i),
                  onFinishEdit: (name) {
                    ref.read(drugSlotsProvider.notifier).setManualName(i, name);
                    setState(() => _editingIndex = null);
                  },
                  rxNormClient: ref.read(rxNormClientProvider),
                ),
                if (i < slots.length - 1) const SizedBox(height: 12),
              ],
              const Spacer(),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Center(child: CircularProgressIndicator()),
                ),
              FilledButton(
                onPressed: _isLoading ? null : _checkInteractions,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
                child: const Text('Check Interactions'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrugConfirmCard extends StatefulWidget {
  final int index;
  final DrugSlot slot;
  final bool isEditing;
  final VoidCallback onStartEdit;
  final ValueChanged<String> onFinishEdit;
  final RxNormClient rxNormClient;

  const _DrugConfirmCard({
    required this.index,
    required this.slot,
    required this.isEditing,
    required this.onStartEdit,
    required this.onFinishEdit,
    required this.rxNormClient,
  });

  @override
  State<_DrugConfirmCard> createState() => _DrugConfirmCardState();
}

class _DrugConfirmCardState extends State<_DrugConfirmCard> {
  final _controller = TextEditingController();
  Timer? _debounce;
  List<String> _suggestions = [];

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    if (value.trim().length < 2) {
      setState(() => _suggestions = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      final results = await widget.rxNormClient.suggest(value.trim());
      if (mounted) setState(() => _suggestions = results);
    });
  }

  @override
  Widget build(BuildContext context) {
    final drug = widget.slot.drug;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Drug ${widget.index + 1}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (widget.isEditing) ...[
              TextField(
                controller: _controller,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Type drug name...',
                  border: OutlineInputBorder(),
                ),
                onChanged: _onChanged,
                onSubmitted: (value) {
                  if (value.trim().isNotEmpty) widget.onFinishEdit(value.trim());
                },
              ),
              if (_suggestions.isNotEmpty)
                ...(_suggestions.map((s) => ListTile(
                      dense: true,
                      title: Text(s),
                      onTap: () => widget.onFinishEdit(s),
                    ))),
            ] else ...[
              Text(
                widget.slot.displayName ?? 'Unknown',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              if (drug?.dosage != null || drug?.form != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    [drug?.dosage, drug?.form]
                        .where((s) => s != null)
                        .join(' · '),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      _controller.text = widget.slot.displayName ?? '';
                      widget.onStartEdit();
                    },
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit'),
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
