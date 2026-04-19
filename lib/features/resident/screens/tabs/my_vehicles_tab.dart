import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/themes.dart';
import '../../../../core/enums/app_enums.dart';
import '../../../../core/models/vehicle_model.dart';
import '../../../../core/widgets/photo_upload_widget.dart';
import '../../../../providers/auth_provider.dart';
import 'dart:io';

class MyVehiclesTab extends ConsumerStatefulWidget {
  final String residentId;
  const MyVehiclesTab({super.key, required this.residentId});

  @override
  ConsumerState<MyVehiclesTab> createState() => _MyVehiclesTabState();
}

class _MyVehiclesTabState extends ConsumerState<MyVehiclesTab> {
  List<VehicleModel> _vehicles = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final fs = ref.read(firestoreServiceProvider);
    final v = await fs.getVehiclesForResident(widget.residentId);
    if (mounted) setState(() { _vehicles = v; _loading = false; });
  }

  Future<void> _showAddSheet() async {
    final plateCtrl = TextEditingController();
    final makeCtrl  = TextEditingController();
    final modelCtrl = TextEditingController();
    final colourCtrl = TextEditingController();
    VehicleType vType = VehicleType.car;
    File? regCardFile;
    final yearCtrl = TextEditingController();
    bool saving = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20,
              MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add Vehicle',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w500)),
              const SizedBox(height: 16),
              TextField(
                controller: plateCtrl,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                    labelText: 'Registration Number *',
                    hintText: 'ABC-1234'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<VehicleType>(
                value: vType,
                decoration:
                    const InputDecoration(labelText: 'Vehicle Type'),
                items: VehicleType.values
                    .map((t) => DropdownMenuItem(
                          value: t,
                          child: Text(t.name[0].toUpperCase() +
                              t.name.substring(1)),
                        ))
                    .toList(),
                onChanged: (v) => setSheet(() => vType = v!),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: makeCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Make'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: modelCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Model'),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              TextField(
                controller: colourCtrl,
                decoration: const InputDecoration(labelText: 'Colour'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: yearCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Year of Manufacture',
                    hintText: '2020'),
              ),
              const SizedBox(height: 16),
              PhotoUploadWidget(
                label: 'Registration card photo *',
                localFile: regCardFile,
                onFilePicked: (f) => setSheet(() => regCardFile = f),
              ),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: saving ? null : () async {
                      if (plateCtrl.text.trim().isEmpty) return;
                      if (regCardFile == null) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(content: Text(
                            'Registration card photo is required')),
                        );
                        return;
                      }
                      setSheet(() => saving = true);
                      final fs = ref.read(firestoreServiceProvider);
                      final storage = ref.read(storageServiceProvider);
                      final vehicle = VehicleModel(
                        id: '',
                        residentId: widget.residentId,
                        vehicleRegistrationNumber:
                            plateCtrl.text.trim().toUpperCase(),
                        make: makeCtrl.text.trim().isEmpty
                            ? null : makeCtrl.text.trim(),
                        model: modelCtrl.text.trim().isEmpty
                            ? null : modelCtrl.text.trim(),
                        colour: colourCtrl.text.trim().isEmpty
                            ? null : colourCtrl.text.trim(),
                        vehicleType: vType,
                        isActive: true,
                        status: 'pending',
                        registeredBy: widget.residentId,
                        registeredAt: DateTime.now(),
                      );
                      final vehicleId = await fs.createVehicle(vehicle);
                      if (regCardFile != null) {
                        final url = await storage
                            .uploadVehicleRegCard(vehicleId, regCardFile!);
                        if (url != null) {
                          await fs.updateVehicle(vehicleId,
                              {'vehicle_registration_card_photo_url': url});
                        }
                      }
                      Navigator.pop(ctx);
                      _load();
                    },
                    child: saving
                        ? const SizedBox(height: 20, width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('Save'),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deactivate(String vehicleId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deactivate vehicle?'),
        content:
            const Text('This vehicle will no longer be tracked at the gate.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Deactivate',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      await ref
          .read(firestoreServiceProvider)
          .updateVehicle(vehicleId, {'is_active': false});
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddSheet,
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _vehicles.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.directions_car_outlined,
                      size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('No vehicles registered yet'),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              itemCount: _vehicles.length,
              itemBuilder: (ctx, i) {
                final v = _vehicles[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          AppTheme.primaryColor.withValues(alpha: 0.1),
                      child: const Icon(Icons.directions_car_outlined,
                          color: AppTheme.primaryColor),
                    ),
                    title: Text(v.vehicleRegistrationNumber,
                        style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1)),
                    subtitle: Text(
                      '\${v.vehicleType.name[0].toUpperCase()}\${v.vehicleType.name.substring(1)}'
                      '\${v.make != null ? " • \${v.make}" : ""}'
                      '\${v.model != null ? " \${v.model}" : ""}'
                      '\${v.colour != null ? " • \${v.colour}" : ""}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _StatusBadge(v.status),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline,
                              color: Colors.red, size: 20),
                          tooltip: 'Deactivate',
                          onPressed: () => _deactivate(v.id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge(this.status);

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'approved'    => Colors.green,
      'underReview' => Colors.blue,
      'rejected'    => Colors.red,
      'cancelled'   => Colors.grey,
      _             => Colors.orange, // pending + fallback
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}
