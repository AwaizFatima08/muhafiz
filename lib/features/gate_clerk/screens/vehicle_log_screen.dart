import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/themes.dart';
import '../../../core/enums/app_enums.dart';
import '../../../core/models/vehicle_event_model.dart';
import '../../../core/utils/validators.dart';
import '../../../providers/auth_provider.dart';

class VehicleLogScreen extends ConsumerStatefulWidget {
  const VehicleLogScreen({super.key});

  @override
  ConsumerState<VehicleLogScreen> createState() => _VehicleLogScreenState();
}

class _VehicleLogScreenState extends ConsumerState<VehicleLogScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _plateCtrl = TextEditingController();
  String _eventType = 'entry';
  bool _submitting  = false;
  String? _error;
  String? _successMsg;

  @override
  void dispose() {
    _plateCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _submitting = true; _error = null; _successMsg = null; });

    try {
      final fs          = ref.read(firestoreServiceProvider);
      final currentUser = ref.read(authStateProvider).valueOrNull;
      if (currentUser == null) throw Exception('Not logged in');

      final plate = _plateCtrl.text.trim().toUpperCase();

      // Look up vehicle by plate
      final vehicle = await fs.getVehicleByPlate(plate);

      final event = VehicleEventModel(
        id:                        '',
        vehicleId:                 vehicle?.id ?? '',
        residentId:                vehicle?.residentId ?? '',
        vehicleRegistrationNumber: plate,
        method:                    VehicleEventMethod.manual,
        eventType:                 _eventType,
        processedBy:               currentUser.uid,
        processedAt:               DateTime.now(),
      );

      await fs.createVehicleEvent(event);

      setState(() {
        _successMsg = '\${_eventType == "entry" ? "Entry" : "Exit"} '
            'logged for \$plate\${vehicle == null ? " (unregistered)" : ""}.';
        _submitting = false;
        _plateCtrl.clear();
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Vehicle Log'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Log Vehicle Event',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text(
                'Manual entry until RFID system is live.',
                style: TextStyle(
                    fontSize: 12, color: Colors.grey.shade500)),
              const SizedBox(height: 20),

              // Event type toggle
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'entry',
                    label: Text('Entry'),
                    icon: Icon(Icons.login_outlined),
                  ),
                  ButtonSegment(
                    value: 'exit',
                    label: Text('Exit'),
                    icon: Icon(Icons.logout_outlined),
                  ),
                ],
                selected: {_eventType},
                onSelectionChanged: (s) =>
                    setState(() => _eventType = s.first),
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _plateCtrl,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Vehicle Registration Number *',
                  prefixIcon: Icon(Icons.directions_car_outlined),
                  hintText: 'ABC-1234',
                ),
                validator: Validators.vehiclePlate,
              ),

              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Text(_error!,
                      style: const TextStyle(
                          color: Colors.red, fontSize: 13)),
                ),
              ],

              if (_successMsg != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: Colors.green.withValues(alpha: 0.3)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.check_circle_outline,
                        color: Colors.green, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(_successMsg!,
                            style: const TextStyle(
                                color: Colors.green, fontSize: 13))),
                  ]),
                ),
              ],

              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _submitting ? null : _submit,
                  icon: _submitting
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Icon(_eventType == 'entry'
                          ? Icons.login_outlined
                          : Icons.logout_outlined),
                  label: Text('Log \${_eventType == "entry" ? "Entry" : "Exit"}'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: _eventType == 'entry'
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
              ),

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 12),

              // Today's vehicle events
              const Text("Today's Vehicle Events",
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Expanded(
                child: StreamBuilder(
                  stream: ref
                      .read(firestoreServiceProvider)
                      .watchTodayVehicleEvents(),
                  builder: (ctx, snap) {
                    if (!snap.hasData || snap.data!.isEmpty) {
                      return Center(
                        child: Text('No vehicle events today',
                            style: TextStyle(
                                color: Colors.grey.shade500)),
                      );
                    }
                    final events = snap.data!;
                    return ListView.builder(
                      itemCount: events.length,
                      itemBuilder: (ctx, i) {
                        final e = events[i];
                        final isEntry = e.eventType == 'entry';
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
                              color: isEntry
                                  ? Colors.green : Colors.red,
                            ),
                          ),
                          title: Text(e.vehicleRegistrationNumber,
                              style: const TextStyle(
                                  fontSize: 13,
                                  letterSpacing: 1)),
                          subtitle: Text(
                            '\${e.processedAt.hour.toString().padLeft(2,"0")}:'
                            '\${e.processedAt.minute.toString().padLeft(2,"0")}',
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
                                color: isEntry
                                    ? Colors.green : Colors.red,
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
            ],
          ),
        ),
      ),
    );
  }
}
