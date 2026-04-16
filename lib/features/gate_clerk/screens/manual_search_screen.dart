import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/themes.dart';
import '../../../core/models/worker_model.dart';
import '../../../providers/auth_provider.dart';
import 'qr_scan_screen.dart';
import 'gate_event_handler.dart';

class ManualSearchScreen extends ConsumerStatefulWidget {
  const ManualSearchScreen({super.key});

  @override
  ConsumerState<ManualSearchScreen> createState() =>
      _ManualSearchScreenState();
}

class _ManualSearchScreenState extends ConsumerState<ManualSearchScreen> {
  final _searchController = TextEditingController();
  WorkerModel? _foundWorker;
  bool _searching = false;
  String? _error;

  Future<void> _search() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    final ctx = context;

    setState(() {
      _searching = true;
      _error = null;
      _foundWorker = null;
    });

    final firestoreService = ref.read(firestoreServiceProvider);
    WorkerModel? worker;

    // Try CNIC first, then card number
    if (query.contains('-')) {
      worker = await firestoreService.getWorkerByCnic(query);
    }
    if (worker == null) {
      // Search by card number via active workers stream
      final workers = await firestoreService.watchActiveWorkers().first;
      worker = workers.where((w) =>
          w.cardNumber.toLowerCase() == query.toLowerCase()).firstOrNull;
    }

    setState(() {
      _searching = false;
      _foundWorker = worker;
      if (worker == null) _error = 'No active worker found for "\$query"';
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manual Search'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextFormField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'CNIC or Card Number',
                hintText: 'e.g. 31304-2047905-7 or EC-2026-0001',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    : IconButton(
                        icon: const Icon(Icons.arrow_forward),
                        onPressed: _search,
                      ),
              ),
              onFieldSubmitted: (_) => _search(),
              textInputAction: TextInputAction.search,
            ),
            const SizedBox(height: 20),
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: AppTheme.errorColor, size: 18),
                    const SizedBox(width: 8),
                    Text(_error!,
                        style:
                            const TextStyle(color: AppTheme.errorColor)),
                  ],
                ),
              ),
            if (_foundWorker != null) ...[
              const SizedBox(height: 16),
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48, height: 48,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor
                                  .withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.person,
                                color: AppTheme.primaryColor),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_foundWorker!.workerName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16)),
                                Text(_foundWorker!.cardNumber,
                                    style: const TextStyle(
                                        color: AppTheme.primaryColor,
                                        fontSize: 13)),
                                Text(_foundWorker!.cnic,
                                    style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final currentUser = ref
                                .read(authStateProvider)
                                .valueOrNull;
                            final firestoreService =
                                ref.read(firestoreServiceProvider);
                            final assignment = await firestoreService
                                .getActiveAssignmentForWorker(
                                    _foundWorker!.id);
                            final presence = await firestoreService
                                .getPresence(_foundWorker!.id);

                            if (!mounted) return;

                            final result = await showModalBottomSheet<Map<String, dynamic>>(
                              context: context,
                              isScrollControlled: true,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(20)),
                              ),
                              builder: (sheetCtx) => WorkerGateProfileSheet(
                                worker: _foundWorker!,
                                assignment: assignment,
                                currentStatus:
                                    presence?.currentStatus ?? 'outside',
                                processedBy: currentUser?.uid ?? '',
                              ),
                            );

                            if (result != null && mounted) {
                              await GateEventHandler.process(
                                ref: ref,
                                worker: _foundWorker!,
                                assignment: assignment,
                                eventType:
                                    result['eventType'] as String,
                                overrideReason: result['overrideReason']
                                    as String?,
                                processedBy: currentUser?.uid ?? '',
                              );
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        "${result['eventType'] == 'entry' ? 'Entry' : 'Exit'} recorded"),
                                    backgroundColor:
                                        result['eventType'] == 'entry'
                                            ? Colors.green
                                            : Colors.orange,
                                  ),
                                );
                                Navigator.pop(context);
                              }
                            }
                          },
                          icon: const Icon(Icons.how_to_reg_outlined),
                          label: const Text('Process Gate Event'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
