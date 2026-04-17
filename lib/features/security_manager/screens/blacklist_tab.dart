import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/models/blacklist_entry_model.dart';

class BlacklistTab extends StatelessWidget {
  final String siteId;
  const BlacklistTab({super.key, required this.siteId});

  void _showAddDialog(BuildContext context) {
    final fs = FirestoreService();
    final cardCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add to Blacklist'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: cardCtrl,
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              if (cardCtrl.text.isEmpty || reasonCtrl.text.isEmpty) return;
              final uid = FirebaseAuth.instance.currentUser!.uid;
              final worker =
                  await fs.getWorkerByCardNumber(cardCtrl.text.trim());
              if (worker == null) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Worker not found')),
                  );
                }
                return;
              }
              await fs.addToBlacklist(
                workerId: worker.id,
                workerName: worker.workerName,
                cardNumber: worker.cardNumber,
                reason: reasonCtrl.text.trim(),
                blacklistedBy: uid,
                blacklistedByRole: 'securityManager',
              );
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Blacklist'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fs = FirestoreService();
    final currentUid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context),
        icon: const Icon(Icons.block),
        label: const Text('Add'),
        backgroundColor: Colors.red,
      ),
      body: StreamBuilder<List<BlacklistEntryModel>>(
        stream: fs.watchBlacklistEntries(),
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final entries = snap.data ?? [];
          if (entries.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.verified_user, size: 64, color: Colors.green),
                  SizedBox(height: 12),
                  Text('No blacklisted workers'),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: entries.length,
            itemBuilder: (_, i) {
              final e = entries[i];
              return Card(
                color: Colors.red.shade50,
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.red,
                    child: Icon(Icons.block, color: Colors.white),
                  ),
                  title: Text(e.workerName,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle:
                      Text('Card: ${e.cardNumber}\nReason: ${e.reason}'),
                  isThreeLine: true,
                  trailing: TextButton(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Override Blacklist?'),
                          content: Text('Allow ${e.workerName} back on site?'),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel')),
                            ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Override')),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await fs.overrideBlacklist(
                          workerId: e.workerId,
                          overrideByUid: currentUid,
                        );
                      }
                    },
                    child: const Text('Override'),
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
