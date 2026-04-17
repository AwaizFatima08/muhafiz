import 'package:flutter/material.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/models/registration_request_model.dart';

class ApprovalsTab extends StatelessWidget {
  final String siteId;
  const ApprovalsTab({super.key, required this.siteId});

  @override
  Widget build(BuildContext context) {
    final fs = FirestoreService();
    return StreamBuilder<List<RegistrationRequestModel>>(
      stream: fs.watchPendingRequests(),
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
                Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
                SizedBox(height: 12),
                Text('No pending approvals'),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (_, i) {
            final r = requests[i];
            final name = r.employeeData['worker_name'] ?? r.employeeData['name'] ?? 'Unknown';
            final cnic = r.employeeData['cnic'] ?? '—';
            final card = r.employeeData['card_number'] ?? '—';
            return Card(
              child: ListTile(
                title: Text(name),
                subtitle: Text('CNIC: $cnic\nCard: $card'),
                isThreeLine: true,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check_circle, color: Colors.green),
                      onPressed: () => fs.updateRegistrationRequest(
                        r.id,
                        {'status': 'approved'},
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.red),
                      onPressed: () => fs.updateRegistrationRequest(
                        r.id,
                        {'status': 'rejected'},
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
