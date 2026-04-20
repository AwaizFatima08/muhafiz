import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../config/themes.dart';
import '../../../../core/enums/app_enums.dart';
import '../../../../core/models/family_member_model.dart';
import '../../../../providers/auth_provider.dart';

class MyFamilyTab extends ConsumerStatefulWidget {
  final String residentId;
  const MyFamilyTab({super.key, required this.residentId});

  @override
  ConsumerState<MyFamilyTab> createState() => _MyFamilyTabState();
}

class _MyFamilyTabState extends ConsumerState<MyFamilyTab> {
  List<FamilyMemberModel> _members = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final fs = ref.read(firestoreServiceProvider);
    final members = await fs.getFamilyMembers(widget.residentId);
    if (mounted) setState(() { _members = members; _loading = false; });
  }

  // A1 FIX: single helper so DOB formatting is consistent between the
  // list subtitle and the bottom sheet picker display.
  String _formatDob(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/'
      '${d.year}';

  Future<void> _showAddEditSheet([FamilyMemberModel? existing]) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final dlNoCtrl  = TextEditingController(
        text: existing?.drivingLicenseNumber ?? '');
    final cnicCtrl  = TextEditingController(text: existing?.cnic ?? '');
    DateTime? dob   = existing?.dateOfBirth != null
        ? DateTime.tryParse(existing!.dateOfBirth!)
        : null;
    FamilyRelation relation =
        existing?.relation ?? FamilyRelation.other;
    bool married   = existing?.married ?? false;
    bool permanent = existing?.permanentResident ?? true;
    bool dlHolder  = existing?.drivingLicenseHolder ?? false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                existing == null ? 'Add Family Member' : 'Edit Member',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration:
                    const InputDecoration(labelText: 'Full Name *'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<FamilyRelation>(
                initialValue: relation,
                decoration:
                    const InputDecoration(labelText: 'Relation'),
                items: FamilyRelation.values
                    .map((r) => DropdownMenuItem(
                          value: r,
                          child: Text(
                              '${r.name[0].toUpperCase()}${r.name.substring(1)}'),
                        ))
                    .toList(),
                onChanged: (v) => setSheet(() => relation = v!),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: cnicCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'CNIC (optional, 18+)',
                    hintText: '13 digits without dashes'),
              ),
              const SizedBox(height: 12),
              // Date of Birth picker
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: dob ?? DateTime(2000),
                    firstDate: DateTime(1930),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setSheet(() => dob = picked);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                      labelText: 'Date of Birth (optional)'),
                  // A1 FIX: use _formatDob helper instead of
                  // inline interpolation that was broken in the original.
                  child: Text(
                    dob != null ? _formatDob(dob!) : 'Select date',
                    style: TextStyle(
                        color: dob != null ? null : Colors.grey),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Married'),
                value: married,
                contentPadding: EdgeInsets.zero,
                onChanged: (v) => setSheet(() => married = v),
              ),
              SwitchListTile(
                title: const Text('Permanent Resident'),
                value: permanent,
                contentPadding: EdgeInsets.zero,
                onChanged: (v) => setSheet(() => permanent = v),
              ),
              SwitchListTile(
                title: const Text('Driving License Holder'),
                value: dlHolder,
                contentPadding: EdgeInsets.zero,
                onChanged: (v) => setSheet(() => dlHolder = v),
              ),
              if (dlHolder) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: dlNoCtrl,
                  decoration:
                      const InputDecoration(labelText: 'License Number'),
                ),
              ],
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
                    onPressed: () async {
                      if (nameCtrl.text.trim().isEmpty) return;
                      final fs = ref.read(firestoreServiceProvider);
                      final member = FamilyMemberModel(
                        memberId: existing?.memberId ?? const Uuid().v4(),
                        name: nameCtrl.text.trim(),
                        relation: relation,
                        cnic: cnicCtrl.text.trim().isEmpty
                            ? null
                            : cnicCtrl.text.trim(),
                        dateOfBirth: dob?.toIso8601String(),
                        married: married,
                        permanentResident: permanent,
                        drivingLicenseHolder: dlHolder,
                        drivingLicenseNumber: dlHolder &&
                                dlNoCtrl.text.trim().isNotEmpty
                            ? dlNoCtrl.text.trim()
                            : null,
                      );
                      await fs.saveFamilyMember(widget.residentId, member);
                      if (ctx.mounted) Navigator.pop(ctx);
                      _load();
                    },
                    child: const Text('Save'),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _delete(String memberId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove member?'),
        content: const Text(
            'This will remove them from your family records.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Remove',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      final fs = ref.read(firestoreServiceProvider);
      await fs.deleteFamilyMember(widget.residentId, memberId);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddEditSheet,
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _members.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.family_restroom, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('No family members added yet'),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              itemCount: _members.length,
              itemBuilder: (ctx, i) {
                final m = _members[i];
                // A1 FIX: build subtitle parts as a list so DOB and flags
                // are only included when present — no stray "null" strings.
                final subtitleParts = [
                  '${m.relation.name[0].toUpperCase()}${m.relation.name.substring(1)}',
                  if (m.dateOfBirth != null)
                    'DOB: ${_formatDob(DateTime.parse(m.dateOfBirth!))}',
                  if (m.permanentResident) 'Permanent',
                  if (m.drivingLicenseHolder) 'DL Holder',
                ];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          AppTheme.primaryColor.withValues(alpha: 0.1),
                      child: Text(
                        m.name.isNotEmpty
                            ? m.name[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(m.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w500)),
                    subtitle: Text(
                      subtitleParts.join(' · '),
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          onPressed: () => _showAddEditSheet(m),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              size: 20, color: Colors.red),
                          onPressed: () => _delete(m.memberId),
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
