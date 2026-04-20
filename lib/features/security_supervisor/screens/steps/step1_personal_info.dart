import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/themes.dart';
import '../../../../core/enums/app_enums.dart';
import '../../../../core/utils/validators.dart';
import '../../../../providers/registration_form_provider.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../core/widgets/photo_upload_widget.dart';
import 'dart:io';

class Step1PersonalInfo extends ConsumerStatefulWidget {
  // D2 FIX: when set, initState pre-loads name/cnic from the
  // resident-initiated registration_request document.
  final String? pendingRequestId;
  const Step1PersonalInfo({super.key, this.pendingRequestId});

  @override
  ConsumerState<Step1PersonalInfo> createState() => _Step1PersonalInfoState();
}

class _Step1PersonalInfoState extends ConsumerState<Step1PersonalInfo> {
  final _formKey        = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _cnicController = TextEditingController();
  bool _checkingCnic    = false;
  File? _workerPhotoFile;
  File? _cnicFrontFile;
  File? _cnicBackFile;

  @override
  void initState() {
    super.initState();
    final state = ref.read(registrationFormProvider);
    _nameController.text = state.name;
    _cnicController.text = state.cnic;
    // D2 FIX: pre-load from resident-initiated request if provided
    if (widget.pendingRequestId != null) {
      _preloadFromRequest(widget.pendingRequestId!);
    }
  }

  Future<void> _preloadFromRequest(String requestId) async {
    final fs      = ref.read(firestoreServiceProvider);
    final notifier = ref.read(registrationFormProvider.notifier);
    try {
      // Load the registration_request document to pre-fill the form
      final fs2 = fs; // same service
      // Use a direct Firestore fetch via updateRegistrationRequest path
      // We read via watchPendingRequests and find by id
      final requests = await fs2.watchPendingRequests().first;
      final req = requests.where((r) => r.id == requestId).firstOrNull;
      if (req == null || !mounted) return;
      final data = req.employeeData;
      final name = data['worker_name'] as String? ?? '';
      final cnic = data['cnic'] as String? ?? '';
      _nameController.text = name;
      _cnicController.text = cnic;
      notifier.updateStep1(name: name, cnic: cnic);
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cnicController.dispose();
    super.dispose();
  }

  Widget _buildPhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Photos',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(
          'All photos optional — can be added later by supervisor',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
        const SizedBox(height: 12),
        PhotoUploadWidget(
          label: 'Worker photo',
          localFile: _workerPhotoFile,
          onFilePicked: (f) => setState(() => _workerPhotoFile = f),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: PhotoUploadWidget(
              label: 'CNIC front',
              localFile: _cnicFrontFile,
              onFilePicked: (f) => setState(() => _cnicFrontFile = f),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: PhotoUploadWidget(
              label: 'CNIC back',
              localFile: _cnicBackFile,
              onFilePicked: (f) => setState(() => _cnicBackFile = f),
            ),
          ),
        ]),
      ],
    );
  }

  Future<void> _checkCnicAndProceed() async {
    if (!_formKey.currentState!.validate()) return;

    final notifier        = ref.read(registrationFormProvider.notifier);
    final firestoreService = ref.read(firestoreServiceProvider);

    setState(() => _checkingCnic = true);
    notifier.setError(null);

    // B1 FIX: strip dashes before querying — CNIC is stored without dashes.
    final cleanCnic = Validators.cleanCnic(_cnicController.text);

    final existing = await firestoreService.getWorkerByCnic(cleanCnic);

    setState(() => _checkingCnic = false);

    if (existing != null) {
      notifier.setCnicDuplicate(true);
      // A3 FIX: error is now displayed in the UI error banner below.
      notifier.setError(
        'CNIC already registered. '
        'Worker: ${existing.workerName} (Card: ${existing.cardNumber})',
      );
      return;
    }

    notifier.setCnicDuplicate(false);
    notifier.updateStep1(
      name:              _nameController.text.trim(),
      // B1 FIX: store cleaned CNIC (no dashes) in form state.
      cnic:              cleanCnic,
      photoUrl:          _workerPhotoFile?.path ?? '',
      cnicPhotoUrlFront: _cnicFrontFile?.path ?? '',
      cnicPhotoUrlBack:  _cnicBackFile?.path ?? '',
    );
    notifier.nextStep();
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(registrationFormProvider);
    final notifier  = ref.read(registrationFormProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Photo uploads ────────────────────────────────────────
            _buildPhotoSection(),
            const SizedBox(height: 24),

            // Full name
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Full Name *',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (v) =>
                  Validators.required(v, fieldName: 'Full name'),
            ),
            const SizedBox(height: 16),

            // CNIC — B1 FIX: hint updated to '13 digits, no dashes'
            // matching the storage format. Old hint 'XXXXX-XXXXXXX-X'
            // implied dashes were acceptable, contradicting arch rules.
            TextFormField(
              controller: _cnicController,
              keyboardType: TextInputType.number,
              maxLength: 13,
              decoration: InputDecoration(
                labelText: 'CNIC *',
                prefixIcon: const Icon(Icons.badge_outlined),
                hintText: '13 digits, no dashes',
                counterText: '',
                suffixIcon: formState.cnicDuplicate
                    ? const Icon(Icons.warning,
                        color: AppTheme.errorColor)
                    : null,
              ),
              onChanged: (_) {
                if (formState.cnicDuplicate) {
                  notifier.setCnicDuplicate(false);
                  notifier.setError(null);
                }
              },
              validator: Validators.cnic,
            ),
            const SizedBox(height: 16),

            // CNIC Expiry
            _DatePickerField(
              label: 'CNIC Expiry Date *',
              initialValue: formState.cnicExpiry,
              icon: Icons.calendar_today_outlined,
              firstDate: DateTime.now(),
              lastDate: DateTime(2050),
              onChanged: (date) => notifier.updateStep1(cnicExpiry: date),
              validator: (v) =>
                  Validators.futureDate(v, fieldName: 'CNIC expiry'),
            ),
            const SizedBox(height: 16),

            // Date of Birth
            _DatePickerField(
              label: 'Date of Birth *',
              initialValue: formState.dob,
              icon: Icons.cake_outlined,
              firstDate: DateTime(1950),
              lastDate: DateTime.now()
                  .subtract(const Duration(days: 365 * 18)),
              onChanged: (date) => notifier.updateStep1(dob: date),
              validator: (v) => Validators.minimumAge(v),
            ),
            const SizedBox(height: 16),

            // Worker Type
            DropdownButtonFormField<WorkerType>(
              initialValue: formState.workerType,
              decoration: const InputDecoration(
                labelText: 'Worker Type *',
                prefixIcon: Icon(Icons.work_outline),
              ),
              items: WorkerType.values
                  .map((type) => DropdownMenuItem(
                        value: type,
                        child: Text(_workerTypeLabel(type)),
                      ))
                  .toList(),
              onChanged: (v) => notifier.updateStep1(workerType: v),
            ),
            const SizedBox(height: 16),

            // Nature of Service
            DropdownButtonFormField<NatureOfService>(
              initialValue: formState.natureOfService,
              decoration: const InputDecoration(
                labelText: 'Nature of Service *',
                prefixIcon: Icon(Icons.schedule_outlined),
              ),
              items: NatureOfService.values
                  .map((type) => DropdownMenuItem(
                        value: type,
                        child: Text(_serviceLabel(type)),
                      ))
                  .toList(),
              onChanged: (v) => notifier.updateStep1(natureOfService: v),
            ),
            const SizedBox(height: 16),

            // A3/B1 FIX: error banner — setError() was being called on
            // CNIC duplicate but the error was never shown in the UI.
            if (formState.errorMessage != null) ...[
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
                    child: Text(
                      formState.errorMessage!,
                      style: const TextStyle(
                          color: Colors.red, fontSize: 13),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 16),
            ],

            // Next button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    _checkingCnic ? null : _checkCnicAndProceed,
                child: _checkingCnic
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Next: Employment Info'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _workerTypeLabel(WorkerType type) {
    return switch (type) {
      WorkerType.houseMaid => 'House Maid',
      WorkerType.driver    => 'Driver',
      WorkerType.servant   => 'Servant',
      WorkerType.cook      => 'Cook',
      WorkerType.tutor     => 'Tutor',
      WorkerType.carWasher => 'Car Washer',
      WorkerType.qari      => 'Qari',
      WorkerType.other     => 'Other',
    };
  }

  String _serviceLabel(NatureOfService type) {
    return switch (type) {
      NatureOfService.fullTime => 'Full Time',
      NatureOfService.dayCare  => 'Day Care',
    };
  }
}

// ── Reusable date picker field ────────────────────────────────────────────────
class _DatePickerField extends StatelessWidget {
  final String label;
  final DateTime? initialValue;
  final IconData icon;
  final DateTime firstDate;
  final DateTime lastDate;
  final ValueChanged<DateTime> onChanged;
  final FormFieldValidator<DateTime>? validator;

  const _DatePickerField({
    required this.label,
    required this.initialValue,
    required this.icon,
    required this.firstDate,
    required this.lastDate,
    required this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return FormField<DateTime>(
      initialValue: initialValue,
      validator: validator,
      builder: (field) {
        return InkWell(
          onTap: () async {
            // Clamp initialDate to [firstDate, lastDate] range to avoid
            // assertion errors when the stored value is out of range.
            final now = DateTime.now();
            DateTime safeInitial = initialValue ?? now;
            if (safeInitial.isBefore(firstDate)) safeInitial = firstDate;
            if (safeInitial.isAfter(lastDate)) safeInitial = lastDate;

            final picked = await showDatePicker(
              context: context,
              initialDate: safeInitial,
              firstDate: firstDate,
              lastDate: lastDate,
            );
            if (picked != null) {
              field.didChange(picked);
              onChanged(picked);
            }
          },
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: label,
              prefixIcon: Icon(icon),
              errorText: field.errorText,
            ),
            child: Text(
              field.value != null
                  ? '${field.value!.day.toString().padLeft(2, '0')}/'
                    '${field.value!.month.toString().padLeft(2, '0')}/'
                    '${field.value!.year}'
                  : 'Select date',
              style: TextStyle(
                color: field.value != null
                    ? Theme.of(context).textTheme.bodyLarge?.color
                    : Colors.grey,
              ),
            ),
          ),
        );
      },
    );
  }
}
