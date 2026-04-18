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
  const Step1PersonalInfo({super.key});

  @override
  ConsumerState<Step1PersonalInfo> createState() => _Step1PersonalInfoState();
}

class _Step1PersonalInfoState extends ConsumerState<Step1PersonalInfo> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _cnicController = TextEditingController();
  bool _checkingCnic = false;
  File? _workerPhotoFile;
  File? _cnicFrontFile;
  File? _cnicBackFile;

  @override
  void initState() {
    super.initState();
    final state = ref.read(registrationFormProvider);
    _nameController.text = state.name;
    _cnicController.text = state.cnic;
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
        Text('All photos optional — can be added later by supervisor',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
        const SizedBox(height: 12),
        PhotoUploadWidget(
          label: 'Worker photo',
          localFile: _workerPhotoFile,
          onFilePicked: (f) => setState(() => _workerPhotoFile = f),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
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
          ],
        ),
      ],
    );
  }

  Future<void> _checkCnicAndProceed() async {
    if (!_formKey.currentState!.validate()) return;

    final notifier = ref.read(registrationFormProvider.notifier);
    final firestoreService = ref.read(firestoreServiceProvider);

    setState(() => _checkingCnic = true);
    notifier.setError(null);

    final existing = await firestoreService.getWorkerByCnic(_cnicController.text.trim());

    setState(() => _checkingCnic = false);

    if (existing != null) {
      notifier.setCnicDuplicate(true);
      notifier.setError(
          'CNIC already registered. Worker: \${existing.name} (Card: \${existing.cardNumber})');
      return;
    }

    notifier.setCnicDuplicate(false);
    notifier.updateStep1(
      name: _nameController.text.trim(),
      cnic: _cnicController.text.trim(),
      photoUrl: _workerPhotoFile?.path ?? '',
      cnicPhotoUrlFront: _cnicFrontFile?.path ?? '',
      cnicPhotoUrlBack: _cnicBackFile?.path ?? '',
    );
    notifier.nextStep();
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(registrationFormProvider);
    final notifier = ref.read(registrationFormProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Photo uploads ──────────────────────────────────────
            _buildPhotoSection(),
            const SizedBox(height: 20),
            // REMOVED old camera stub — replaced with PhotoUploadWidget
            // ignore: dead_code
            if (false) Center(
              child: GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Camera coming soon')),
                  );
                },
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: AppTheme.primaryColor.withValues(alpha: 0.3),
                        width: 2),
                  ),
                  child: formState.photoUrl.isEmpty
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt_outlined,
                                color: AppTheme.primaryColor, size: 32),
                            const SizedBox(height: 4),
                            Text('Photo',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.primaryColor)),
                          ],
                        )
                      : ClipOval(
                          child: Image.network(formState.photoUrl,
                              fit: BoxFit.cover)),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Name
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

            // CNIC
            TextFormField(
              controller: _cnicController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'CNIC *',
                prefixIcon: const Icon(Icons.badge_outlined),
                hintText: 'XXXXX-XXXXXXX-X',
                suffixIcon: formState.cnicDuplicate
                    ? const Icon(Icons.warning, color: AppTheme.errorColor)
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
              validator: (v) => Validators.futureDate(v, fieldName: 'CNIC expiry'),
            ),
            const SizedBox(height: 16),

            // Date of Birth
            _DatePickerField(
              label: 'Date of Birth *',
              initialValue: formState.dob,
              icon: Icons.cake_outlined,
              firstDate: DateTime(1950),
              lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
              onChanged: (date) => notifier.updateStep1(dob: date),
              validator: (v) => Validators.minimumAge(v),
            ),
            const SizedBox(height: 16),

            // Worker Type
            DropdownButtonFormField<WorkerType>(
              value: formState.workerType,
              decoration: const InputDecoration(
                labelText: 'Worker Type *',
                prefixIcon: Icon(Icons.work_outline),
              ),
              items: WorkerType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(_workerTypeLabel(type)),
                );
              }).toList(),
              onChanged: (v) => notifier.updateStep1(workerType: v),
            ),
            const SizedBox(height: 16),

            // Nature of Service
            DropdownButtonFormField<NatureOfService>(
              value: formState.natureOfService,
              decoration: const InputDecoration(
                labelText: 'Nature of Service *',
                prefixIcon: Icon(Icons.schedule_outlined),
              ),
              items: NatureOfService.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(_serviceLabel(type)),
                );
              }).toList(),
              onChanged: (v) => notifier.updateStep1(natureOfService: v),
            ),
            const SizedBox(height: 32),

            // Next button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _checkingCnic ? null : _checkCnicAndProceed,
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
    switch (type) {
      case WorkerType.houseMaid: return 'House Maid';
      case WorkerType.driver: return 'Driver';
      case WorkerType.servant: return 'Servant';
      case WorkerType.cook: return 'Cook';
      case WorkerType.tutor: return 'Tutor';
      case WorkerType.carWasher: return 'Car Washer';
      case WorkerType.qari: return 'Qari';
      case WorkerType.other: return 'Other';
    }
  }

  String _serviceLabel(NatureOfService type) {
    switch (type) {
      case NatureOfService.fullTime: return 'Full Time';
      
      case NatureOfService.dayCare: return 'Day Care';
      
    }
  }
}

// Reusable date picker field widget
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
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () async {
                final clampedInitial = initialValue != null
                    ? initialValue!
                    : (DateTime.now().isAfter(lastDate) ? lastDate : DateTime.now());
                final picked = await showDatePicker(
                  context: context,
                  initialDate: clampedInitial,
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
                      ? '${field.value!.day.toString().padLeft(2, "0")}/${field.value!.month.toString().padLeft(2, "0")}/${field.value!.year}'
                      : 'Select date',
                  style: TextStyle(
                    color: field.value != null
                        ? Theme.of(context).textTheme.bodyLarge?.color
                        : Colors.grey,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
