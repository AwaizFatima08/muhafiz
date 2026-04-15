import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../config/themes.dart';
import '../../../../core/enums/app_enums.dart';
import '../../../../core/models/worker_model.dart';
import '../../../../core/models/worker_assignment_model.dart';
import '../../../../core/utils/card_number_generator.dart';
import '../../../../providers/registration_form_provider.dart';
import '../../../../providers/auth_provider.dart';

class Step3PoliceVerification extends ConsumerStatefulWidget {
  const Step3PoliceVerification({super.key});

  @override
  ConsumerState<Step3PoliceVerification> createState() =>
      _Step3PoliceVerificationState();
}

class _Step3PoliceVerificationState
    extends ConsumerState<Step3PoliceVerification> {
  final _formKey = GlobalKey<FormState>();
  final _refController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final state = ref.read(registrationFormProvider);
    _refController.text = state.policeVerifRefNumber;
  }

  @override
  void dispose() {
    _refController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final notifier = ref.read(registrationFormProvider.notifier);
    final formState = ref.read(registrationFormProvider);
    final firestoreService = ref.read(firestoreServiceProvider);
    final db = FirebaseFirestore.instance;

    notifier.setSubmitting(true);
    notifier.setError(null);

    try {
      // Generate card number
      final cardNumber = await CardNumberGenerator.generate(db);

      // Generate QR value
      final qrValue = 'MHZ-\${DateTime.now().millisecondsSinceEpoch}';

      final now = DateTime.now();

      // Create worker
      final worker = WorkerModel(
        id: '',
        cardNumber: cardNumber,
        name: formState.name,
        cnic: formState.cnic,
        cnicExpiry: formState.cnicExpiry,
        dob: formState.dob,
        photoUrl: formState.photoUrl.isEmpty ? null : formState.photoUrl,
        workerType: formState.workerType,
        natureOfService: formState.natureOfService,
        policeVerified: formState.policeVerified,
        policeVerifDate: formState.policeVerifDate,
        policeVerifRefNumber: _refController.text.trim().isEmpty
            ? null
            : _refController.text.trim(),
        policeVerifExpiry: formState.policeVerifExpiry,
        status: WorkerStatus.pendingApproval,
        qrCodeValue: qrValue,
        qrInvalidated: false,
        createdAt: now,
        updatedAt: now,
      );

      final workerId = await firestoreService.createWorker(worker);

      // Create assignment
      final currentUser = ref.read(authStateProvider).valueOrNull;
      final assignment = WorkerAssignmentModel(
        id: '',
        workerId: workerId,
        employerId: formState.employerId,
        houseNumber: formState.houseNumber,
        arrivalWindow: formState.arrivalWindow,
        status: AssignmentStatus.active,
        approvedBy: currentUser?.uid ?? '',
        approvedAt: now,
        subEmployers: [],
      );

      await firestoreService.createAssignment(assignment);

      notifier.setSubmitting(false);

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text('Worker Registered'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Name: \${formState.name}'),
                Text('Card No: \$cardNumber'),
                const SizedBox(height: 8),
                const Text(
                  'Status: Pending Approval',
                  style: TextStyle(color: Colors.orange),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  notifier.reset();
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                child: const Text('Done'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      notifier.setSubmitting(false);
      notifier.setError('Registration failed: \$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(registrationFormProvider);
    final notifier = ref.read(registrationFormProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Police Verification',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'Fill in if worker has police verification. Can be updated later.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 20),

            // Police verified toggle
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SwitchListTile(
                title: const Text('Police Verified'),
                subtitle: const Text('Worker has valid police verification'),
                value: formState.policeVerified,
                activeThumbColor: AppTheme.primaryColor,
                onChanged: (v) => notifier.updateStep3(policeVerified: v),
              ),
            ),
            const SizedBox(height: 16),

            if (formState.policeVerified) ...[
              // Ref number
              TextFormField(
                controller: _refController,
                decoration: const InputDecoration(
                  labelText: 'Reference Number *',
                  prefixIcon: Icon(Icons.numbers_outlined),
                ),
                validator: formState.policeVerified
                    ? (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Reference number required when verified';
                        }
                        return null;
                      }
                    : null,
              ),
              const SizedBox(height: 16),

              // Verification date
              _DatePickerField(
                label: 'Verification Date *',
                initialValue: formState.policeVerifDate,
                icon: Icons.calendar_today_outlined,
                firstDate: DateTime(2000),
                lastDate: DateTime.now(),
                onChanged: (date) =>
                    notifier.updateStep3(policeVerifDate: date),
                validator: formState.policeVerified
                    ? (v) {
                        if (v == null) return 'Verification date required';
                        return null;
                      }
                    : null,
              ),
              const SizedBox(height: 16),

              // Expiry date
              _DatePickerField(
                label: 'Verification Expiry *',
                initialValue: formState.policeVerifExpiry,
                icon: Icons.event_outlined,
                firstDate: DateTime.now(),
                lastDate: DateTime(2050),
                onChanged: (date) =>
                    notifier.updateStep3(policeVerifExpiry: date),
                validator: formState.policeVerified
                    ? (v) {
                        if (v == null) return 'Expiry date required';
                        return null;
                      }
                    : null,
              ),
              const SizedBox(height: 16),
            ],

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
                  Text('Registration Summary',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor)),
                  const Divider(),
                  _SummaryRow('Name', formState.name),
                  _SummaryRow('CNIC', formState.cnic),
                  _SummaryRow('Worker Type',
                      formState.workerType.name),
                  _SummaryRow('House', formState.houseNumber),
                  _SummaryRow('Arrival', formState.arrivalWindow),
                  _SummaryRow('Police Verified',
                      formState.policeVerified ? 'Yes' : 'No'),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Navigation buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: formState.isSubmitting
                        ? null
                        : () => notifier.prevStep(),
                    child: const Text('Back'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: formState.isSubmitting ? null : _submit,
                    child: formState.isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('Register Worker'),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12, color: Colors.grey)),
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
            final picked = await showDatePicker(
              context: context,
              initialDate: initialValue ?? DateTime.now(),
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
              initialValue != null
                  ? '${initialValue!.day.toString().padLeft(2, "0")}/${initialValue!.month.toString().padLeft(2, "0")}/${initialValue!.year}'
                  : 'Select date',
              style: TextStyle(
                color: initialValue != null
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
