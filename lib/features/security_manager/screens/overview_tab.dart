import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../core/services/firestore_service.dart';

class OverviewTab extends StatefulWidget {
  final String siteId;
  const OverviewTab({super.key, required this.siteId});

  @override
  State<OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<OverviewTab> {
  final _fs = FirestoreService();
  int _thresholdHours = 8;

  @override
  void initState() {
    super.initState();
    _loadThreshold();
  }

  Future<void> _loadThreshold() async {
    final settings = await _fs.getSiteSettings(widget.siteId);
    if (settings != null && mounted) {
      setState(() => _thresholdHours = settings.overstayThresholdHours);
    }
  }

  void _editThreshold() {
    final controller = TextEditingController(text: _thresholdHours.toString());
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Set Overstay Threshold'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Hours',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final hours = int.tryParse(controller.text);
              if (hours != null && hours > 0) {
                await _fs.updateOverstayThreshold(widget.siteId, hours);
                if (mounted) {
                  setState(() => _thresholdHours = hours);
                  Navigator.pop(context);
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: StreamBuilder<int>(
                stream: _fs.activeWorkersInsideCount(),
                builder: (_, snap) => _StatCard(
                  label: 'Inside Now',
                  value: '${snap.data ?? 0}',
                  icon: Icons.people,
                  color: Colors.blue,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _fs.overstayWorkers(widget.siteId, _thresholdHours),
                builder: (_, snap) => _StatCard(
                  label: 'Overstays',
                  value: '${snap.data?.length ?? 0}',
                  icon: Icons.timer_off,
                  color: Colors.red,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StreamBuilder<int>(
                stream: _fs.totalActiveWorkersCount(),
                builder: (_, snap) => _StatCard(
                  label: 'Total Active',
                  value: '${snap.data ?? 0}',
                  icon: Icons.badge,
                  color: Colors.green,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Card(
          child: ListTile(
            leading: const Icon(Icons.tune),
            title: const Text('Overstay Threshold'),
            subtitle: Text('Currently: $_thresholdHours hours'),
            trailing: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _editThreshold,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text('Overstay Alerts',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: _fs.overstayWorkers(widget.siteId, _thresholdHours),
          builder: (_, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final workers = snap.data ?? [];
            if (workers.isEmpty) {
              return const Card(
                child: ListTile(
                  leading: Icon(Icons.check_circle, color: Colors.green),
                  title: Text('No overstay alerts'),
                ),
              );
            }
            return Column(
              children: workers.map((w) {
                final entryTime =
                    (w['last_event_time'] as Timestamp).toDate();
                final duration = DateTime.now().difference(entryTime);
                final hours = duration.inHours;
                final minutes = duration.inMinutes % 60;
                return Card(
                  color: Colors.red.shade50,
                  child: ListTile(
                    leading: const Icon(Icons.warning, color: Colors.red),
                    title: Text(w['worker_name'] ?? 'Unknown'),
                    subtitle: Text(
                        'Card: ${w['card_number'] ?? ''}\nInside for ${hours}h ${minutes}m'),
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

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: color, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
