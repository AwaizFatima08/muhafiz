import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/themes.dart';
import '../../../core/enums/app_enums.dart';
import '../../../core/models/resident_model.dart';
import '../../../core/models/organisation_model.dart';
import '../../../core/utils/validators.dart';
import '../../../providers/auth_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _nameCtrl   = TextEditingController();
  final _phoneCtrl  = TextEditingController();
  final _cnicCtrl   = TextEditingController();
  final _empNoCtrl  = TextEditingController();
  final _dlNoCtrl   = TextEditingController();
  final _blockCtrl  = TextEditingController();
  final _sectorCtrl = TextEditingController();

  String? _selectedOrgId;
  String? _selectedGrade;
  String? _selectedDept;
  DateTime? _dob;
  DateTime? _dlExpiry;

  List<OrganisationModel> _orgs = [];
  bool _loading   = true;
  bool _saving    = false;
  String? _error;

  ResidentModel? _current;

  List<String> get _grades => _orgs
      .where((o) => o.id == _selectedOrgId)
      .firstOrNull?.grades ?? [];
  List<String> get _departments => _orgs
      .where((o) => o.id == _selectedOrgId)
      .firstOrNull?.departments ?? [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final fs  = ref.read(firestoreServiceProvider);
    final uid = ref.read(authStateProvider).valueOrNull?.uid;
    if (uid == null) return;

    final resident = await fs.getResident(uid);
    final orgs     = await fs.getOrganisations();

    if (mounted && resident != null) {
      setState(() {
        _current        = resident;
        _orgs           = orgs;
        _nameCtrl.text  = resident.name;
        _phoneCtrl.text = resident.phoneMobile;
        _cnicCtrl.text  = resident.cnic ?? '';
        _empNoCtrl.text = resident.employeeNumber ?? '';
        _dlNoCtrl.text  = resident.drivingLicenseNumber ?? '';
        _blockCtrl.text = resident.block ?? '';
        _sectorCtrl.text = resident.sector ?? '';
        _selectedOrgId  = resident.organisationId;
        _selectedGrade  = resident.grade;
        _selectedDept   = resident.department;
        _dlExpiry       = resident.drivingLicenseExpiryDate != null
            ? DateTime.tryParse(resident.drivingLicenseExpiryDate!) : null;
        _loading        = false;
      });
    }
  }

  @override
  void dispose() {
    for (final c in [_nameCtrl, _phoneCtrl, _cnicCtrl, _empNoCtrl,
        _dlNoCtrl, _blockCtrl, _sectorCtrl]) { c.dispose(); }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _saving = true; _error = null; });

    try {
      final fs  = ref.read(firestoreServiceProvider);
      final uid = ref.read(authStateProvider).valueOrNull?.uid;
      if (uid == null) throw Exception('Not logged in');

      final empFormatted = _empNoCtrl.text.trim().isEmpty ? null
          : Validators.formatEmployeeNumber(_empNoCtrl.text.trim());

      await fs.updateResident(uid, {
        'name':                   _nameCtrl.text.trim(),
        'phone_mobile':           Validators.cleanPhone(_phoneCtrl.text),
        'cnic':                   Validators.cleanCnic(_cnicCtrl.text),
        'employee_number':        empFormatted,
        'organisation_id':        _selectedOrgId,
        'grade':                  _selectedGrade,
        'department':             _selectedDept,
        'block':                  _blockCtrl.text.trim().isEmpty
            ? null : _blockCtrl.text.trim(),
        'sector':                 _sectorCtrl.text.trim().isEmpty
            ? null : _sectorCtrl.text.trim(),
        'driving_license_number': _dlNoCtrl.text.trim().isEmpty
            ? null : _dlNoCtrl.text.trim(),
        'driving_license_expiry_date': _dlExpiry?.toIso8601String(),
        'date_of_birth': _dob?.toIso8601String(),
        // Reset approval status — changes require re-approval
        'status':    ResidentStatus.pending.name,
        'is_active': false,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Profile updated. Pending re-approval by security office.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
        context.pop();
      }
    } catch (e) {
      setState(() {
        _error  = e.toString().replaceAll('Exception: ', '');
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('Save',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Current status banner
              if (_current?.status != ResidentStatus.approved)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.4)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.info_outline,
                        color: Colors.orange, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Status: ${_current?.status.name ?? 'unknown'}. '
                        'Saving will reset to pending for re-approval.',
                        style: const TextStyle(
                            color: Colors.orange, fontSize: 13),
                      ),
                    ),
                  ]),
                ),

              _SectionHeader('Personal Information'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                    labelText: 'Full Name *',
                    prefixIcon: Icon(Icons.person_outline)),
                validator: (v) =>
                    Validators.required(v, fieldName: 'Full name'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cnicCtrl,
                keyboardType: TextInputType.number,
                maxLength: 13,
                decoration: const InputDecoration(
                    labelText: 'CNIC',
                    prefixIcon: Icon(Icons.badge_outlined),
                    hintText: '13 digits no dashes',
                    counterText: ''),
                validator: (v) => v == null || v.isEmpty
                    ? null : Validators.cnic(v),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                maxLength: 11,
                decoration: const InputDecoration(
                    labelText: 'Mobile Number *',
                    prefixIcon: Icon(Icons.phone_outlined),
                    hintText: '03XXXXXXXXXX',
                    counterText: ''),
                validator: Validators.phone,
              ),
              const SizedBox(height: 24),

              _SectionHeader('Organisation'),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedOrgId,
                decoration: const InputDecoration(
                    labelText: 'Organisation',
                    prefixIcon: Icon(Icons.business_outlined)),
                items: _orgs.map((o) => DropdownMenuItem(
                        value: o.id, child: Text(o.name))).toList(),
                onChanged: (v) => setState(() {
                  _selectedOrgId = v;
                  _selectedGrade = null;
                  _selectedDept  = null;
                }),
              ),
              if (_selectedOrgId != null && _departments.isNotEmpty) ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedDept,
                  decoration: const InputDecoration(
                      labelText: 'Department',
                      prefixIcon: Icon(Icons.account_tree_outlined)),
                  items: _departments.map((d) => DropdownMenuItem(
                          value: d, child: Text(d))).toList(),
                  onChanged: (v) => setState(() => _selectedDept = v),
                ),
              ],
              if (_selectedOrgId != null && _grades.isNotEmpty) ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedGrade,
                  decoration: const InputDecoration(
                      labelText: 'Grade',
                      prefixIcon: Icon(Icons.grade_outlined)),
                  items: _grades.map((g) => DropdownMenuItem(
                          value: g, child: Text(g))).toList(),
                  onChanged: (v) => setState(() => _selectedGrade = v),
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _empNoCtrl,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                    labelText: 'Employee / Service Number',
                    prefixIcon: Icon(Icons.badge_outlined),
                    hintText: 'FFL-00123'),
                validator: Validators.employeeNumber,
              ),
              const SizedBox(height: 24),

              _SectionHeader('Address'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: TextFormField(
                    controller: _blockCtrl,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(labelText: 'Block'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _sectorCtrl,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(labelText: 'Sector'),
                  ),
                ),
              ]),
              const SizedBox(height: 24),

              _SectionHeader('Driving License'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _dlNoCtrl,
                decoration: const InputDecoration(
                    labelText: 'License Number',
                    prefixIcon: Icon(Icons.drive_eta_outlined)),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _dlExpiry ??
                        DateTime.now().add(const Duration(days: 365)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2050),
                  );
                  if (picked != null) setState(() => _dlExpiry = picked);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                      labelText: 'License Expiry Date',
                      prefixIcon: Icon(Icons.calendar_today_outlined)),
                  child: Text(
                    _dlExpiry != null
                        ? '${_dlExpiry!.day.toString().padLeft(2,'0')}/'
                          '${_dlExpiry!.month.toString().padLeft(2,'0')}/'
                          '${_dlExpiry!.year}'
                        : 'Select date',
                    style: TextStyle(
                        color: _dlExpiry != null ? null : Colors.grey),
                  ),
                ),
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
                  child: Row(children: [
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_error!,
                        style: const TextStyle(
                            color: Colors.red, fontSize: 13))),
                  ]),
                ),
              ],
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
                letterSpacing: 0.5)),
        const Divider(height: 8),
      ],
    );
  }
}
