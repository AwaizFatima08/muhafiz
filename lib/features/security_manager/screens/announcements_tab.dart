import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/announcement_model.dart';
import '../../../providers/auth_provider.dart';

class AnnouncementsTab extends ConsumerStatefulWidget {
  const AnnouncementsTab({super.key});

  @override
  ConsumerState<AnnouncementsTab> createState() => _AnnouncementsTabState();
}

class _AnnouncementsTabState extends ConsumerState<AnnouncementsTab> {
  final _titleCtrl   = TextEditingController();
  final _bodyCtrl    = TextEditingController();
  String _audience   = 'all';
  bool _sending      = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_titleCtrl.text.trim().isEmpty || _bodyCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title and message are required')),
      );
      return;
    }
    setState(() => _sending = true);
    try {
      final fs          = ref.read(firestoreServiceProvider);
      final currentUser = ref.read(authStateProvider).valueOrNull;

      final announcement = AnnouncementModel(
        id:       '',
        title:    _titleCtrl.text.trim(),
        body:     _bodyCtrl.text.trim(),
        sentBy:   currentUser?.uid ?? '',
        sentAt:   DateTime.now(),
        audience: _audience,
      );

      await fs.createAnnouncement(announcement);

      _titleCtrl.clear();
      _bodyCtrl.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Announcement sent'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: \$e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fs = ref.read(firestoreServiceProvider);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Compose ───────────────────────────────────────────────────────
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('New Announcement',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                TextField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Title *',
                    prefixIcon: Icon(Icons.title),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _bodyCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Message *',
                    prefixIcon: Icon(Icons.message_outlined),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _audience,
                  decoration: const InputDecoration(
                    labelText: 'Audience',
                    prefixIcon: Icon(Icons.group_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'all',       child: Text('All')),
                    DropdownMenuItem(value: 'residents', child: Text('Residents only')),
                    DropdownMenuItem(value: 'security',  child: Text('Security staff only')),
                  ],
                  onChanged: (v) => setState(() => _audience = v!),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _sending ? null : _send,
                    icon: _sending
                        ? const SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send_outlined),
                    label: const Text('Send Announcement'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // ── Recent announcements ──────────────────────────────────────────
        const Text('Recent Announcements',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        StreamBuilder<List<AnnouncementModel>>(
          stream: fs.watchRecentAnnouncements(limit: 20),
          builder: (_, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final items = snap.data ?? [];
            if (items.isEmpty) {
              return const Card(
                child: ListTile(
                  leading: Icon(Icons.notifications_none),
                  title: Text('No announcements yet'),
                ),
              );
            }
            return Column(
              children: items.map((a) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.withValues(alpha: 0.1),
                      child: const Icon(Icons.campaign_outlined,
                          color: Colors.blue),
                    ),
                    title: Text(a.title,
                        style: const TextStyle(fontWeight: FontWeight.w500)),
                    subtitle: Text('\${a.body}\n\$timeStr · \${a.audience}',
                        maxLines: 3, overflow: TextOverflow.ellipsis),
                    isThreeLine: true,
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}
