import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/themes.dart';
import '../../../../core/enums/app_enums.dart';
import '../../../../core/models/pet_model.dart';
import '../../../../core/widgets/photo_upload_widget.dart';
import '../../../../providers/auth_provider.dart';
import 'dart:io';

class MyPetsTab extends ConsumerStatefulWidget {
  final String residentId;
  const MyPetsTab({super.key, required this.residentId});

  @override
  ConsumerState<MyPetsTab> createState() => _MyPetsTabState();
}

class _MyPetsTabState extends ConsumerState<MyPetsTab> {
  List<PetModel> _pets = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final fs = ref.read(firestoreServiceProvider);
    final p = await fs.getPetsForResident(widget.residentId);
    if (mounted) setState(() { _pets = p; _loading = false; });
  }

  Future<void> _showAddSheet() async {
    final nameCtrl  = TextEditingController();
    final breedCtrl = TextEditingController();
    PetType petType = PetType.dog;
    bool vaccinated = false;
    File? photoFile;
    File? vacDocFile;
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
              const Text('Pet Registration Request',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text(
                'Your request will be reviewed by the security office.',
                style: TextStyle(
                    fontSize: 12, color: Colors.grey.shade500)),
              const SizedBox(height: 16),
              DropdownButtonFormField<PetType>(
                value: petType,
                decoration:
                    const InputDecoration(labelText: 'Pet Type *'),
                items: PetType.values
                    .map((t) => DropdownMenuItem(
                          value: t,
                          child: Text(t.name[0].toUpperCase() +
                              t.name.substring(1)),
                        ))
                    .toList(),
                onChanged: (v) => setSheet(() => petType = v!),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                    labelText: 'Pet Name (optional)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: breedCtrl,
                decoration:
                    const InputDecoration(labelText: 'Breed (optional)'),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Vaccination up to date'),
                value: vaccinated,
                contentPadding: EdgeInsets.zero,
                onChanged: (v) => setSheet(() => vaccinated = v),
              ),
              const SizedBox(height: 8),
              PhotoUploadWidget(
                label: 'Pet photo (optional)',
                localFile: photoFile,
                onFilePicked: (f) => setSheet(() => photoFile = f),
              ),
              const SizedBox(height: 12),
              PhotoUploadWidget(
                label: 'Vaccination document (optional)',
                localFile: vacDocFile,
                onFilePicked: (f) => setSheet(() => vacDocFile = f),
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
                      setSheet(() => saving = true);
                      final fs = ref.read(firestoreServiceProvider);
                      final storage = ref.read(storageServiceProvider);
                      final pet = PetModel(
                        id: '',
                        residentId: widget.residentId,
                        requestedBy: widget.residentId,
                        petType: petType,
                        petName: nameCtrl.text.trim().isEmpty
                            ? null : nameCtrl.text.trim(),
                        breed: breedCtrl.text.trim().isEmpty
                            ? null : breedCtrl.text.trim(),
                        vaccinationStatus: vaccinated,
                        status: PetStatus.pending,
                        requestInitiatedAt: DateTime.now(),
                      );
                      final petId = await fs.createPetRequest(pet);
                      if (photoFile != null) {
                        final url = await storage
                            .uploadPetPhoto(petId, photoFile!);
                        if (url != null) {
                          await fs.updatePet(petId, {'photo_url': url});
                        }
                      }
                      if (vacDocFile != null) {
                        final url = await storage
                            .uploadPetVaccinationDoc(petId, vacDocFile!);
                        if (url != null) {
                          await fs.updatePet(petId,
                              {'vaccination_doc_url': url});
                        }
                      }
                      Navigator.pop(ctx);
                      _load();
                    },
                    child: saving
                        ? const SizedBox(height: 20, width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('Submit Request'),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(PetStatus s) {
    switch (s) {
      case PetStatus.approved: return Colors.green;
      case PetStatus.rejected: return Colors.red;
      case PetStatus.pending:  return Colors.orange;
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
      body: _pets.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.pets, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('No pet requests yet'),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              itemCount: _pets.length,
              itemBuilder: (ctx, i) {
                final p = _pets[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          AppTheme.primaryColor.withValues(alpha: 0.1),
                      child: const Icon(Icons.pets,
                          color: AppTheme.primaryColor),
                    ),
                    title: Text(
                      p.petName ??
                          '\${p.petType.name[0].toUpperCase()}\${p.petType.name.substring(1)}',
                      style:
                          const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      p.breed != null ? p.breed! : p.petType.name,
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _statusColor(p.status)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: _statusColor(p.status)
                                .withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        p.status.name[0].toUpperCase() +
                            p.status.name.substring(1),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _statusColor(p.status),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
