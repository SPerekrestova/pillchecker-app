import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/providers.dart';
import '../services/api_client.dart';
import '../services/rxnorm_client.dart';
import '../widgets/drug_slot.dart';

class DrugInputScreen extends ConsumerStatefulWidget {
  const DrugInputScreen({super.key});

  @override
  ConsumerState<DrugInputScreen> createState() => _DrugInputScreenState();
}

class _DrugInputScreenState extends ConsumerState<DrugInputScreen> {
  bool _isLoading = false;
  String? _error;
  int? _lastScanSlot;

  Future<void> _handleScan(int slotIndex) async {
    setState(() {
      _isLoading = true;
      _error = null;
      _lastScanSlot = slotIndex;
    });

    try {
      HapticFeedback.mediumImpact();
      final ocrService = ref.read(ocrServiceProvider);
      // Use gallery in debug/simulator, camera on real device
      final text = await ocrService.scanText(useGallery: kDebugMode);

      if (!mounted) return;

      if (text == null) {
        setState(() => _isLoading = false);
        return;
      }

      final apiClient = ref.read(apiClientProvider);
      final result = await apiClient.analyze(text);

      if (!mounted) return;

      if (result.drugs.isEmpty) {
        setState(() {
          _error = 'No medications detected. Try better lighting or enter manually.';
          _isLoading = false;
        });
        return;
      }

      ref.read(drugSlotsProvider.notifier).setDrug(slotIndex, result.drugs.first);
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

  void _handleType(int slotIndex) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _DrugSearchSheet(
        onSelected: (name) {
          ref.read(drugSlotsProvider.notifier).setManualName(slotIndex, name);
          Navigator.pop(context);
        },
        rxNormClient: ref.read(rxNormClientProvider),
      ),
    );
  }

  void _checkInteractions() {
    context.go('/confirm');
  }

  @override
  Widget build(BuildContext context) {
    final slots = ref.watch(drugSlotsProvider);
    final bothFilled = slots.every((s) => s.isFilled);

    return Scaffold(
      appBar: AppBar(title: const Text('PillChecker')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!slots[0].isFilled && !slots[1].isFilled)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    'Scan or type two medications to check interactions',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
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
                          if (_lastScanSlot != null)
                            TextButton(
                              onPressed: () => _handleScan(_lastScanSlot!),
                              child: const Text('Retry'),
                            ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () => setState(() => _error = null),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              DrugSlotWidget(
                slotIndex: 0,
                drugName: slots[0].displayName,
                onScan: _isLoading ? () {} : () => _handleScan(0),
                onType: () => _handleType(0),
                onClear: slots[0].isFilled
                    ? () => ref.read(drugSlotsProvider.notifier).clearSlot(0)
                    : null,
              ),
              const SizedBox(height: 12),
              DrugSlotWidget(
                slotIndex: 1,
                drugName: slots[1].displayName,
                onScan: _isLoading ? () {} : () => _handleScan(1),
                onType: () => _handleType(1),
                onClear: slots[1].isFilled
                    ? () => ref.read(drugSlotsProvider.notifier).clearSlot(1)
                    : null,
              ),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                ),
              const Spacer(),
              FilledButton(
                onPressed: bothFilled ? _checkInteractions : null,
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

/// Bottom sheet for drug name search with RxNorm autocomplete.
class _DrugSearchSheet extends StatefulWidget {
  final ValueChanged<String> onSelected;
  final RxNormClient rxNormClient;

  const _DrugSearchSheet({
    required this.onSelected,
    required this.rxNormClient,
  });

  @override
  State<_DrugSearchSheet> createState() => _DrugSearchSheetState();
}

class _DrugSearchSheetState extends State<_DrugSearchSheet> {
  final _controller = TextEditingController();
  Timer? _debounce;
  List<String> _suggestions = [];
  bool _loading = false;

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
      setState(() => _loading = true);
      final results = await widget.rxNormClient.suggest(value.trim());
      if (mounted) {
        setState(() {
          _suggestions = results;
          _loading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Type drug name...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: _onChanged,
            onSubmitted: (value) {
              if (value.trim().isNotEmpty) {
                widget.onSelected(value.trim());
              }
            },
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          if (_suggestions.isNotEmpty)
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _suggestions.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_suggestions[index]),
                    onTap: () => widget.onSelected(_suggestions[index]),
                  );
                },
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
