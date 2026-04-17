import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/models/termination_request_model.dart';

class TerminationsTab extends StatelessWidget {
  final String siteId;
  const TerminationsTab({super.key, required this.siteId});

  void _showInitiateDialog(BuildContext context) {
    final fs = FirestoreService();
    final workerCardCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Initiate Termination'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: workerCardCtrl,
              decoration: const InputDecoration(
                labelText: 'Worker Card Number',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Reason',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (workerCardCtrl.text.isEmpty || reasonCtrl.text.isEmpty) return;
              final uid = FirebaseAuth.instance.currentUser!.uid;
              final worker =
                  await fs.getWorkerByCardNumber(workerCardCtrl.text.trim());
              if (worker == null) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Worker not found')),
                  );
                }
                return;
              }
              await fs.submitTerminationRequest(
                workerId: worker.id,
                workerName: worker.workerName,
                cardNumber: worker.cardNumber,
                reason: reasonCtrl.text.trim(),
                initiatedBy: uid,
                initiatorRole: 'securityManager',
              );
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fs = FirestoreService();
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showInitiateDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Initiate'),
      ),
      body: StreamBuilder<List<TerminationRequestModel>>(
        stream: fs.watchTerminationRequests(),
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final requests = snap.data ?? [];
          if (requests.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.gavel, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('No pending termination requests'),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (_, i) {
              final r = requests[i];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.person),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(r.workerName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                          Chip(
                            label: Text(r.initiatorRole == 'employer'
                                ? 'Employer'
                                : 'Security'),
                            backgroundColor: r.initiatorRole == 'employer'
                                ? Colors.orange.shade100
                                : Colors.blue.shade100,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('Card: ${r.cardNumber}',
                          style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 4),
                      Text('Reason: ${r.reason}'),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton.icon(
                            icon: const Icon(Icons.close, color: Colors.red),
                            label: const Text('Reject',
                                style: TextStyle(color: Colors.red)),
                            onPressed: () => fs.resolveTerminationRequest(
                              requestId: r.id,
                              workerId: r.workerId,
                              decision: 'rejected',
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.check),
                            label: const Text('Approve'),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red),
                            onPressed: () => fs.resolveTerminationRequest(
                              requestId: r.id,
                              workerId: r.workerId,
                              decision: 'approved',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
