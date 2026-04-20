import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/themes.dart';
import '../../../../core/models/resident_model.dart';
import '../../../../providers/auth_provider.dart';

class NotificationPrefsTab extends ConsumerStatefulWidget {
  final String residentId;
  const NotificationPrefsTab({super.key, required this.residentId});

  @override
  ConsumerState<NotificationPrefsTab> createState() =>
      _NotificationPrefsTabState();
}

class _NotificationPrefsTabState
    extends ConsumerState<NotificationPrefsTab> {
  bool _workerEntry   = true;
  bool _workerExit    = true;
  bool _guestArrival  = true;
  bool _announcements = true;
  bool _loading = true;
  bool _saving  = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final fs = ref.read(firestoreServiceProvider);
    final resident = await fs.getResident(widget.residentId);
    if (resident != null && mounted) {
      final prefs = resident.notificationPrefs;
      setState(() {
        _workerEntry   = prefs.workerEntry;
        _workerExit    = prefs.workerExit;
        _guestArrival  = prefs.guestArrival;
        _announcements = prefs.announcements;
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final fs = ref.read(firestoreServiceProvider);
    await fs.updateResident(widget.residentId, {
      'notification_pref': NotificationPrefs(
        workerEntry:   _workerEntry,
        workerExit:    _workerExit,
        guestArrival:  _guestArrival,
        announcements: _announcements,
      ).toMap(),
    });
    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preferences saved')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Notification Preferences',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Text(
          'Choose which events send you a push notification.',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 20),
        Card(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('Worker entry'),
                subtitle: const Text('When your staff enters the gate'),
                value: _workerEntry,
                activeThumbColor: AppTheme.primaryColor,
                onChanged: (v) => setState(() => _workerEntry = v),
              ),
              const Divider(height: 1, indent: 16),
              SwitchListTile(
                title: const Text('Worker exit'),
                subtitle: const Text('When your staff exits the gate'),
                value: _workerExit,
                activeThumbColor: AppTheme.primaryColor,
                onChanged: (v) => setState(() => _workerExit = v),
              ),
              const Divider(height: 1, indent: 16),
              SwitchListTile(
                title: const Text('Guest arrival'),
                subtitle: const Text('When a visitor arrives for you'),
                value: _guestArrival,
                activeThumbColor: AppTheme.primaryColor,
                onChanged: (v) => setState(() => _guestArrival = v),
              ),
              const Divider(height: 1, indent: 16),
              SwitchListTile(
                title: const Text('Announcements'),
                subtitle: const Text('Township-wide announcements'),
                value: _announcements,
                activeThumbColor: AppTheme.primaryColor,
                onChanged: (v) => setState(() => _announcements = v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  height: 20, width: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Save Preferences'),
        ),
      ],
    );
  }
}
