import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/themes.dart';
import '../../../core/enums/app_enums.dart';
import '../../../core/models/resident_model.dart';
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
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController  = TextEditingController();
  final _nameController     = TextEditingController();
  final _phoneController    = TextEditingController();
  final _formKey1 = GlobalKey<FormState>();
  bool _obscurePw  = true;
  bool _obscureCfm = true;

  // Step 2 — address
  final _houseController   = TextEditingController();
  final _blockController   = TextEditingController();
  final _sectorController  = TextEditingController();
  final _sectionController = TextEditingController();
  final _unitController    = TextEditingController();
  final _deptController    = TextEditingController();
  final _gradeController   = TextEditingController();
  final _empNoController   = TextEditingController();
  final _formKey2 = GlobalKey<FormState>();
  String? _selectedOrgId;
  List<Map<String, dynamic>> _orgs = [];
  bool _loadingOrgs = true;

  // Step 3 — driving license (optional)
  final _dlNumberController = TextEditingController();
  final _formKey3 = GlobalKey<FormState>();
  DateTime? _dlExpiry;

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadOrgs();
  }

  Future<void> _loadOrgs() async {
    final fs = ref.read(firestoreServiceProvider);
    final orgs = await fs.getOrganisations();
    if (mounted) {
      setState(() {
        _orgs = orgs.map((o) => {'id': o.id, 'name': o.name}).toList();
        _loadingOrgs = false;
      });
    }
  }

  @override
  void dispose() {
    for (final c in [
      _emailController, _passwordController, _confirmController,
      _nameController, _phoneController, _houseController,
      _blockController, _sectorController, _sectionController,
      _unitController, _deptController, _gradeController,
      _empNoController, _dlNumberController,
    ]) { c.dispose(); }
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    setState(() => _currentStep++);
    _pageController.nextPage(
        duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  void _prevStep() {
    setState(() => _currentStep--);
    _pageController.previousPage(
        duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  Future<void> _submit() async {
    if (!_formKey3.currentState!.validate()) return;

    setState(() { _isSubmitting = true; _errorMessage = null; });

    try {
      final authService = ref.read(authServiceProvider);
      final fs          = ref.read(firestoreServiceProvider);

      // Check CNIC duplicate not needed for resident (no CNIC at registration)
      // Check email duplicate handled by Firebase Auth

      // Create Firebase Auth account
      await authService.createUser(
        email:    _emailController.text.trim(),
        password: _passwordController.text,
        name:     _nameController.text.trim(),
        phone:    _phoneController.text.trim(),
        role:     UserRole.resident,
      );

      final uid = authService.currentUser?.uid;
      if (uid == null) throw Exception('Account creation failed');

      // Create resident document
      final resident = ResidentModel(
        id:             uid,
        name:           _nameController.text.trim(),
        employeeNumber: _empNoController.text.trim().isEmpty
            ? null : _empNoController.text.trim(),
        organisationId: _selectedOrgId,
        houseNumber:    _houseController.text.trim(),
        block:          _blockController.text.trim().isEmpty
            ? null : _blockController.text.trim(),
        sector:         _sectorController.text.trim().isEmpty
            ? null : _sectorController.text.trim(),
        section:        _sectionController.text.trim().isEmpty
            ? null : _sectionController.text.trim(),
        unit:           _unitController.text.trim().isEmpty
            ? null : _unitController.text.trim(),
        department:     _deptController.text.trim().isEmpty
            ? null : _deptController.text.trim(),
        grade:          _gradeController.text.trim().isEmpty
            ? null : _gradeController.text.trim(),
        phoneMobile:    _phoneController.text.trim(),
        drivingLicenseNumber: _dlNumberController.text.trim().isEmpty
            ? null : _dlNumberController.text.trim(),
        drivingLicenseExpiryDate: _dlExpiry?.toIso8601String(),
        isActive:       false,
        status:         ResidentStatus.pending,
        registeredByUid:  uid,
        registeredByRole: 'resident',
        createdAt:      DateTime.now(),
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
                onPressed: () => context.go('/login'),
              )
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
                  child: Row(
                    children: [
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
                              ? const Icon(Icons.check, size: 16,
                                  color: Colors.white)
                              : Text('${i + 1}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: active
                                        ? Colors.white
                                        : Colors.grey.shade500,
                                  )),
                        ),
                      ),
                      if (i < 2)
                        Expanded(
                          child: Container(
                            height: 2,
                            color: complete
                                ? Colors.green
                                : Colors.grey.shade200,
                          ),
                        ),
                    ],
                  ),
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
          // Pages
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStep1(),
                _buildStep2(),
                _buildStep3(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 1 — Account details ──────────────────────────────────────────────
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
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Full Name *',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (v) => Validators.required(v, fieldName: 'Full name'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Mobile Number *',
                prefixIcon: Icon(Icons.phone_outlined),
                hintText: '03XX-XXXXXXX',
              ),
              validator: Validators.phone,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email *',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: Validators.email,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePw,
              decoration: InputDecoration(
                labelText: 'Password *',
                prefixIcon: const Icon(Icons.lock_outlined),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePw
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscurePw = !_obscurePw),
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
              controller: _confirmController,
              obscureText: _obscureCfm,
              decoration: InputDecoration(
                labelText: 'Confirm Password *',
                prefixIcon: const Icon(Icons.lock_outlined),
                suffixIcon: IconButton(
                  icon: Icon(_obscureCfm
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscureCfm = !_obscureCfm),
                ),
              ),
              validator: (v) {
                if (v != _passwordController.text) return 'Passwords do not match';
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

  // ── Step 2 — Address & organisation ──────────────────────────────────────
  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Address & Organisation',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 20),
            TextFormField(
              controller: _houseController,
              decoration: const InputDecoration(
                labelText: 'House Number *',
                prefixIcon: Icon(Icons.home_outlined),
              ),
              validator: (v) =>
                  Validators.required(v, fieldName: 'House number'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _blockController,
                    decoration: const InputDecoration(
                      labelText: 'Block',
                      prefixIcon: Icon(Icons.grid_view_outlined),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _sectorController,
                    decoration: const InputDecoration(
                      labelText: 'Sector',
                      prefixIcon: Icon(Icons.map_outlined),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _sectionController,
                    decoration: const InputDecoration(labelText: 'Section'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _unitController,
                    decoration: const InputDecoration(labelText: 'Unit'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Organisation dropdown
            _loadingOrgs
                ? const Center(child: CircularProgressIndicator())
                : DropdownButtonFormField<String>(
                    value: _selectedOrgId,
                    decoration: const InputDecoration(
                      labelText: 'Organisation',
                      prefixIcon: Icon(Icons.business_outlined),
                    ),
                    items: _orgs
                        .map((o) => DropdownMenuItem<String>(
                              value: o['id'] as String,
                              child: Text(o['name'] as String),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedOrgId = v),
                  ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _deptController,
                    decoration: const InputDecoration(labelText: 'Department'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _gradeController,
                    decoration: const InputDecoration(labelText: 'Grade'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _empNoController,
              decoration: const InputDecoration(
                labelText: 'Employee / Service Number',
                prefixIcon: Icon(Icons.badge_outlined),
                hintText: 'Leave blank if not applicable',
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _prevStep,
                    child: const Text('Back'),
                  ),
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
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Step 3 — Driving license (optional) + submit ──────────────────────────
  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Driving License',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text('Optional — can be added later from your profile',
                style: TextStyle(
                    fontSize: 12, color: Colors.grey.shade500)),
            const SizedBox(height: 20),
            TextFormField(
              controller: _dlNumberController,
              decoration: const InputDecoration(
                labelText: 'License Number',
                prefixIcon: Icon(Icons.drive_eta_outlined),
              ),
            ),
            const SizedBox(height: 16),
            // DL expiry date picker
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _dlExpiry ?? DateTime.now().add(
                      const Duration(days: 365)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2050),
                );
                if (picked != null) setState(() => _dlExpiry = picked);
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'License Expiry Date',
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                ),
                child: Text(
                  _dlExpiry != null
                      ? '${_dlExpiry!.day.toString().padLeft(2, "0")}/'
                        '${_dlExpiry!.month.toString().padLeft(2, "0")}/'
                        '${_dlExpiry!.year}'
                      : 'Select date (optional)',
                  style: TextStyle(
                    color: _dlExpiry != null
                        ? Theme.of(context).textTheme.bodyLarge?.color
                        : Colors.grey,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Summary
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
                  _SummaryRow('Name', _nameController.text),
                  _SummaryRow('Phone', _phoneController.text),
                  _SummaryRow('Email', _emailController.text),
                  _SummaryRow('House', _houseController.text),
                  if (_selectedOrgId != null)
                    _SummaryRow('Org',
                        _orgs.firstWhere(
                            (o) => o['id'] == _selectedOrgId,
                            orElse: () => {'name': ''})['name'] as String),
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
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_errorMessage!,
                          style: const TextStyle(
                              color: Colors.red, fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSubmitting ? null : _prevStep,
                    child: const Text('Back'),
                  ),
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
              ],
            ),
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
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
