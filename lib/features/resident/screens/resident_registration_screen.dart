import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/themes.dart';
import '../../../core/enums/app_enums.dart';
import '../../../core/models/resident_model.dart';
import '../../../core/models/organisation_model.dart';
import '../../../core/utils/validators.dart';
import '../../../providers/auth_provider.dart';

class ResidentRegistrationScreen extends ConsumerStatefulWidget {
  const ResidentRegistrationScreen({super.key});

  @override
  ConsumerState<ResidentRegistrationScreen> createState() =>
      _ResidentRegistrationScreenState();
}

class _ResidentRegistrationScreenState
    extends ConsumerState<ResidentRegistrationScreen> {
  final _pageController = PageController();
  int _currentStep = 0;

  // Step 1 — account
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl  = TextEditingController();
  final _nameCtrl     = TextEditingController();
  final _phoneCtrl    = TextEditingController();
  final _cnicCtrl     = TextEditingController();
  DateTime? _dob;
  final _formKey1 = GlobalKey<FormState>();
  bool _obscurePw  = true;
  bool _obscureCfm = true;

  // Step 2 — address + org
  final _houseCtrl  = TextEditingController();
  final _blockCtrl  = TextEditingController();
  final _sectorCtrl = TextEditingController();
  final _empNoCtrl  = TextEditingController();
  final _formKey2   = GlobalKey<FormState>();
  String? _selectedOrgId;
  String? _selectedGrade;
  String? _selectedDept;
  List<OrganisationModel> _orgs = [];
  bool _loadingOrgs = true;

  // Step 3 — driving license
  final _dlNumberCtrl = TextEditingController();
  final _formKey3     = GlobalKey<FormState>();
  DateTime? _dlExpiry;

  bool _isSubmitting = false;
  String? _errorMessage;

  // Derived from selected org
  List<String> get _grades => _orgs
      .where((o) => o.id == _selectedOrgId)
      .firstOrNull
      ?.grades ?? [];
  List<String> get _departments => _orgs
      .where((o) => o.id == _selectedOrgId)
      .firstOrNull
      ?.departments ?? [];

  @override
  void initState() {
    super.initState();
    _loadOrgs();
  }

  Future<void> _loadOrgs() async {
    final fs = ref.read(firestoreServiceProvider);
    final orgs = await fs.getOrganisations();
    if (mounted) setState(() { _orgs = orgs; _loadingOrgs = false; });
  }

  @override
  void dispose() {
    for (final c in [
      _emailCtrl, _passwordCtrl, _confirmCtrl, _nameCtrl,
      _phoneCtrl, _cnicCtrl, _houseCtrl, _blockCtrl, _sectorCtrl,
      _empNoCtrl, _dlNumberCtrl,
    ]) { c.dispose(); }
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    setState(() => _currentStep++);
    _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut);
  }

  void _prevStep() {
    setState(() => _currentStep--);
    _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut);
  }

  Future<bool> _checkDuplicates() async {
    final fs = ref.read(firestoreServiceProvider);

    // Check CNIC uniqueness
    final cnicClean = Validators.cleanCnic(_cnicCtrl.text);
    if (cnicClean.isNotEmpty) {
      final exists = await fs.residentCnicExists(cnicClean);
      if (exists) {
        setState(() => _errorMessage = 'This CNIC is already registered.');
        return false;
      }
    }

    // Check house number uniqueness
    final existing =
        await fs.residentByHouseNumber(_houseCtrl.text.trim().toUpperCase());
    if (existing != null) {
      setState(() => _errorMessage =
          'House ${_houseCtrl.text.trim().toUpperCase()} already has a registered resident.');
      return false;
    }

    // Check employee number uniqueness
    if (_empNoCtrl.text.trim().isNotEmpty) {
      final empExists = await fs.residentByEmployeeNumber(
          Validators.formatEmployeeNumber(_empNoCtrl.text.trim()));
      if (empExists != null) {
        setState(() => _errorMessage =
            'This employee number is already registered.');
        return false;
      }
    }

    return true;
  }

  Future<void> _submit() async {
    if (!_formKey3.currentState!.validate()) return;
    setState(() { _isSubmitting = true; _errorMessage = null; });

    try {
      final ok = await _checkDuplicates();
      if (!ok) { setState(() => _isSubmitting = false); return; }

      final authService = ref.read(authServiceProvider);
      final fs          = ref.read(firestoreServiceProvider);

      // Create Firebase Auth account
      await authService.createUser(
        email:    _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        name:     _nameCtrl.text.trim(),
        phone:    Validators.cleanPhone(_phoneCtrl.text),
        role:     UserRole.resident,
      );

      final uid = authService.currentUser?.uid;
      // B3 FIX: guard against null UID — if account creation silently
      // returned without creating a user, we must not proceed to write
      // a resident document with an empty/null id.
      if (uid == null) throw Exception('Account creation failed — please try again.');

      final empFormatted = _empNoCtrl.text.trim().isEmpty
          ? null
          : Validators.formatEmployeeNumber(_empNoCtrl.text.trim());

      // B3 FIX: include dob in the resident document. Previously _dob was
      // captured from the date picker but never passed to ResidentModel,
      // so date of birth was silently dropped on every registration.
      final resident = ResidentModel(
        id:             uid,
        name:           _nameCtrl.text.trim(),
        cnic:           Validators.cleanCnic(_cnicCtrl.text),
        dob:            _dob?.toIso8601String(),          // ← was missing
        employeeNumber: empFormatted,
        organisationId: _selectedOrgId,
        houseNumber:    _houseCtrl.text.trim().toUpperCase(),
        block:          _blockCtrl.text.trim().isEmpty
            ? null : _blockCtrl.text.trim(),
        sector:         _sectorCtrl.text.trim().isEmpty
            ? null : _sectorCtrl.text.trim(),
        department:     _selectedDept,
        grade:          _selectedGrade,
        phoneMobile:    Validators.cleanPhone(_phoneCtrl.text),
        drivingLicenseNumber: _dlNumberCtrl.text.trim().isEmpty
            ? null : _dlNumberCtrl.text.trim(),
        drivingLicenseExpiryDate: _dlExpiry?.toIso8601String(),
        isActive:         false,
        status:           ResidentStatus.pending,
        registeredByUid:  uid,
        registeredByRole: 'resident',
        createdAt:        DateTime.now(),
      );

      await fs.createResident(resident);

      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Row(children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('Registration Submitted'),
            ]),
            content: const Text(
              'Your registration has been submitted for approval.\n\n'
              'You will be able to log in once approved by the security office.',
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.go('/login');
                },
                child: const Text('Back to Login'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Resident Registration'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        leading: _currentStep == 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go('/login'))
            : null,
      ),
      body: Column(
        children: [
          // Step indicator
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: List.generate(3, (i) {
                final active   = i == _currentStep;
                final complete = i < _currentStep;
                return Expanded(
                  child: Row(children: [
                    Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: complete
                            ? Colors.green
                            : active
                                ? AppTheme.primaryColor
                                : Colors.grey.shade200,
                      ),
                      child: Center(
                        child: complete
                            ? const Icon(Icons.check,
                                size: 16, color: Colors.white)
                            : Text('${i + 1}',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: active
                                        ? Colors.white
                                        : Colors.grey.shade500)),
                      ),
                    ),
                    if (i < 2)
                      Expanded(
                          child: Container(
                              height: 2,
                              color: complete
                                  ? Colors.green
                                  : Colors.grey.shade200)),
                  ]),
                );
              }),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('Account', style: TextStyle(fontSize: 11)),
                Text('Address', style: TextStyle(fontSize: 11)),
                Text('License', style: TextStyle(fontSize: 11)),
              ],
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [_buildStep1(), _buildStep2(), _buildStep3()],
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 1 — Account ────────────────────────────────────────────────────
  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Account Details',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 20),
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
            // CNIC — 13 digits, no dashes
            TextFormField(
              controller: _cnicCtrl,
              keyboardType: TextInputType.number,
              maxLength: 13,
              decoration: const InputDecoration(
                  labelText: 'CNIC *',
                  prefixIcon: Icon(Icons.badge_outlined),
                  hintText: '13 digits, no dashes',
                  counterText: ''),
              validator: Validators.cnic,
            ),
            const SizedBox(height: 16),
            // Date of Birth
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _dob ?? DateTime(1985),
                  firstDate: DateTime(1930),
                  lastDate: DateTime.now()
                      .subtract(const Duration(days: 6570)),
                );
                if (picked != null) setState(() => _dob = picked);
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                    labelText: 'Date of Birth',
                    prefixIcon: Icon(Icons.cake_outlined)),
                child: Text(
                  _dob != null
                      ? '${_dob!.day.toString().padLeft(2, '0')}/'
                        '${_dob!.month.toString().padLeft(2, '0')}/${_dob!.year}'
                      : 'Select date (optional)',
                  style: TextStyle(
                      color: _dob != null ? null : Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Phone — 11 digits, no dashes
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              maxLength: 11,
              decoration: const InputDecoration(
                  labelText: 'Mobile Number *',
                  prefixIcon: Icon(Icons.phone_outlined),
                  hintText: '03XXXXXXXXXX (11 digits)',
                  counterText: ''),
              validator: Validators.phone,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                  labelText: 'Email *',
                  prefixIcon: Icon(Icons.email_outlined)),
              validator: Validators.email,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordCtrl,
              obscureText: _obscurePw,
              decoration: InputDecoration(
                labelText: 'Password *',
                prefixIcon: const Icon(Icons.lock_outlined),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePw
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined),
                  onPressed: () =>
                      setState(() => _obscurePw = !_obscurePw),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Password is required';
                if (v.length < 6) return 'Minimum 6 characters';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmCtrl,
              obscureText: _obscureCfm,
              decoration: InputDecoration(
                labelText: 'Confirm Password *',
                prefixIcon: const Icon(Icons.lock_outlined),
                suffixIcon: IconButton(
                  icon: Icon(_obscureCfm
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined),
                  onPressed: () =>
                      setState(() => _obscureCfm = !_obscureCfm),
                ),
              ),
              validator: (v) {
                if (v != _passwordCtrl.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_formKey1.currentState!.validate()) _nextStep();
                },
                child: const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Step 2 — Address & Organisation ────────────────────────────────────
  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Address & Organisation',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 20),
            // House number with format hint
            TextFormField(
              controller: _houseCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                  labelText: 'House Number *',
                  prefixIcon: Icon(Icons.home_outlined),
                  hintText: 'e.g. BQ-12, A-150, D+-5'),
              validator: Validators.houseNumber,
            ),
            const SizedBox(height: 16),
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
            const SizedBox(height: 16),
            // Organisation dropdown
            _loadingOrgs
                ? const Center(child: CircularProgressIndicator())
                : DropdownButtonFormField<String>(
                    initialValue: _selectedOrgId,
                    decoration: const InputDecoration(
                        labelText: 'Organisation *',
                        prefixIcon: Icon(Icons.business_outlined)),
                    items: _orgs
                        .map((o) => DropdownMenuItem(
                              value: o.id,
                              child: Text(o.name),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() {
                      _selectedOrgId = v;
                      _selectedGrade = null;
                      _selectedDept  = null;
                    }),
                    validator: (v) =>
                        v == null ? 'Select organisation' : null,
                  ),
            const SizedBox(height: 16),
            // Department — shown only when org has departments
            if (_selectedOrgId != null && _departments.isNotEmpty) ...[
              DropdownButtonFormField<String>(
                initialValue: _selectedDept,
                decoration: const InputDecoration(
                    labelText: 'Department',
                    prefixIcon: Icon(Icons.account_tree_outlined)),
                items: _departments
                    .map((d) =>
                        DropdownMenuItem(value: d, child: Text(d)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedDept = v),
              ),
              const SizedBox(height: 16),
            ],
            // Grade — shown only when org has grades
            if (_selectedOrgId != null && _grades.isNotEmpty) ...[
              DropdownButtonFormField<String>(
                initialValue: _selectedGrade,
                decoration: const InputDecoration(
                    labelText: 'Grade',
                    prefixIcon: Icon(Icons.grade_outlined)),
                items: _grades
                    .map((g) =>
                        DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedGrade = v),
              ),
              const SizedBox(height: 16),
            ],
            // Employee / service number — B5: format hint + validator
            TextFormField(
              controller: _empNoCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                  labelText: 'Employee / Service Number',
                  prefixIcon: Icon(Icons.badge_outlined),
                  hintText: 'FFL-00123'),
              validator: Validators.employeeNumber,
            ),
            const SizedBox(height: 32),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                    onPressed: _prevStep, child: const Text('Back')),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey2.currentState!.validate()) _nextStep();
                  },
                  child: const Text('Continue'),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  // ── Step 3 — Driving license + submit ──────────────────────────────────
  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Driving License',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(
              'Optional — can be added later from your profile',
              style: TextStyle(
                  fontSize: 12, color: Colors.grey.shade500)),
            const SizedBox(height: 20),
            TextFormField(
              controller: _dlNumberCtrl,
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
                      ? '${_dlExpiry!.day.toString().padLeft(2, '0')}/'
                        '${_dlExpiry!.month.toString().padLeft(2, '0')}/${_dlExpiry!.year}'
                      : 'Select date (optional)',
                  style: TextStyle(
                      color: _dlExpiry != null ? null : Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Summary card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppTheme.primaryColor.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Summary',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor)),
                  const Divider(),
                  _SummaryRow('Name',  _nameCtrl.text),
                  _SummaryRow('Phone', _phoneCtrl.text),
                  _SummaryRow('Email', _emailCtrl.text),
                  _SummaryRow('House', _houseCtrl.text.toUpperCase()),
                  if (_selectedOrgId != null)
                    _SummaryRow(
                        'Org',
                        _orgs
                                .where((o) => o.id == _selectedOrgId)
                                .firstOrNull
                                ?.name ??
                            ''),
                  if (_selectedDept != null)
                    _SummaryRow('Dept', _selectedDept!),
                  if (_selectedGrade != null)
                    _SummaryRow('Grade', _selectedGrade!),
                ],
              ),
            ),
            if (_errorMessage != null) ...[
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
                  Expanded(
                      child: Text(_errorMessage!,
                          style: const TextStyle(
                              color: Colors.red, fontSize: 13))),
                ]),
              ),
            ],
            const SizedBox(height: 32),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                    onPressed: _isSubmitting ? null : _prevStep,
                    child: const Text('Back')),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Submit Registration'),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        SizedBox(
            width: 60,
            child: Text(label,
                style:
                    const TextStyle(fontSize: 12, color: Colors.grey))),
        Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w500))),
      ]),
    );
  }
}
