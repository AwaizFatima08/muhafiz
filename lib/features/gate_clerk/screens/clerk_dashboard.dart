import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/themes.dart';
import '../../../core/models/presence_model.dart';
import '../../../providers/auth_provider.dart';

class ClerkDashboard extends ConsumerWidget {
  const ClerkDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firestoreService = ref.read(firestoreServiceProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Gate Clerk'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authServiceProvider).signOut();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Presence counter banner
          StreamBuilder<List<PresenceModel>>(
            stream: firestoreService.watchWorkersInside(),
            builder: (context, snapshot) {
              final count = snapshot.data?.length ?? 0;
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    vertical: 16, horizontal: 20),
                color: AppTheme.primaryColor.withValues(alpha: 0.08),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.people_outline,
                          color: AppTheme.primaryColor, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Workers Inside',
                            style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600)),
                        Text('$count',
                            style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor)),
                      ],
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => context.push('/clerk/inside-list'),
                      icon: const Icon(Icons.list_alt_outlined, size: 18),
                      label: const Text('View All'),
                    ),
                  ],
                ),
              );
            },
          ),

          // Main scan button
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => context.push('/clerk/scan'),
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withValues(alpha: 0.4),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.qr_code_scanner,
                              color: Colors.white, size: 72),
                          SizedBox(height: 8),
                          Text('SCAN',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('Tap to scan worker QR code',
                      style: TextStyle(
                          color: Colors.grey.shade500, fontSize: 14)),
                  const SizedBox(height: 40),
                  // Manual search option
                  OutlinedButton.icon(
                    onPressed: () => context.push('/clerk/manual-search'),
                    icon: const Icon(Icons.search),
                    label: const Text('Manual Search'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Recent events
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Recent Events',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                TextButton(
                  onPressed: () => context.push('/clerk/gate-log'),
                  child: const Text('See All'),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 200,
            child: StreamBuilder(
              stream: firestoreService.watchTodayGateEvents(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Text('No events today',
                        style: TextStyle(color: Colors.grey.shade500)),
                  );
                }
                final events = snapshot.data!.take(5).toList();
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final event = events[index];
                    final isEntry = event.eventType == 'entry';
                    return ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: isEntry
                            ? Colors.green.withValues(alpha: 0.15)
                            : Colors.red.withValues(alpha: 0.15),
                        child: Icon(
                          isEntry
                              ? Icons.login_outlined
                              : Icons.logout_outlined,
                          size: 16,
                          color: isEntry ? Colors.green : Colors.red,
                        ),
                      ),
                      title: Text(event.workerId,
                          style: const TextStyle(fontSize: 13)),
                      subtitle: Text(
                        event.processedAt.toString().substring(11, 16),
                        style: const TextStyle(fontSize: 11),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isEntry
                              ? Colors.green.withValues(alpha: 0.1)
                              : Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isEntry ? 'Entry' : 'Exit',
                          style: TextStyle(
                            fontSize: 11,
                            color: isEntry ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
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
