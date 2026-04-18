import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/validators.dart';
import '../../../../providers/registration_form_provider.dart';
import '../../../../providers/auth_provider.dart';

class Step2EmploymentInfo extends ConsumerStatefulWidget {
  const Step2EmploymentInfo({super.key});

  @override
  ConsumerState<Step2EmploymentInfo> createState() => _Step2EmploymentInfoState();
}

class _Step2EmploymentInfoState extends ConsumerState<Step2EmploymentInfo> {
  final _formKey = GlobalKey<FormState>();
  final _houseController = TextEditingController();
  final _arrivalController = TextEditingController();
  String? _selectedEmployerId;
  bool _loadingEmployers = true;
  String? _arrivalFrom;
  String? _arrivalTo;
  static final List<String> _timeSlots = List.generate(48,
    (i) => "${(i ~/ 2).toString().padLeft(2, '0')}:${i.isOdd ? '30' : '00'}");
  List<Map<String, dynamic>> _employers = [];

  @override
  void initState() {
    super.initState();
    final state = ref.read(registrationFormProvider);
    _houseController.text = state.houseNumber;
    // arrivalWindow stored as 'HH:MM-HH:MM'
    final parts = state.arrivalWindow.split('-');
    _arrivalFrom = parts.isNotEmpty && parts[0].isNotEmpty ? parts[0] : null;
    _arrivalTo   = parts.length > 1 && parts[1].isNotEmpty ? parts[1] : null;
    _selectedEmployerId = state.residentId.isEmpty ? null : state.residentId;
    _loadEmployers();
  }

  Future<void> _loadEmployers() async {
    final firestoreService = ref.read(firestoreServiceProvider);
    final employers = await firestoreService.watchActiveResidents().first;
    if (mounted) {
      setState(() {
        _employers = employers
            .map((e) => {'id': e.id, 'name': e.name, 'unit': e.unit ?? ''})
            .toList();
        _loadingEmployers = false;
      });
    }
  }

  @override
  void dispose() {
    _houseController.dispose();
    _arrivalController.dispose();
    super.dispose();
  }

  void _proceed() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedEmployerId == null) return;

    final notifier = ref.read(registrationFormProvider.notifier);
    notifier.updateStep2(
      residentId: _selectedEmployerId,
      houseNumber: _houseController.text.trim(),
      arrivalWindow: _arrivalController.text.trim(),
    );
    notifier.nextStep();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(registrationFormProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Employment Details',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            // Employer selector
            _loadingEmployers
                ? const Center(child: CircularProgressIndicator())
                : DropdownButtonFormField<String>(
                    value: _selectedEmployerId,
                    decoration: const InputDecoration(
                      labelText: 'Primary Employer *',
                      prefixIcon: Icon(Icons.home_outlined),
                    ),
                    hint: const Text('Select employer'),
                    items: _employers.map((e) {
                      return DropdownMenuItem<String>(
                        value: e['id'],
                        child: Text('${e["name"]} — ${e["unit"]}'),
                      );
                    }).toList(),
                    onChanged: (v) => setState(() => _selectedEmployerId = v),
                    validator: (v) =>
                        v == null ? 'Please select an employer' : null,
                  ),
            const SizedBox(height: 16),

            // House number
            TextFormField(
              controller: _houseController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'House Number *',
                prefixIcon: Icon(Icons.house_outlined),
                hintText: 'e.g. A-123',
              ),
              validator: (v) =>
                  Validators.required(v, fieldName: 'House number'),
            ),
            const SizedBox(height: 16),

            // Arrival window
            TextFormField(
              controller: _arrivalController,
              decoration: const InputDecoration(
                labelText: 'Expected Arrival Window *',
                prefixIcon: Icon(Icons.access_time_outlined),
                hintText: 'e.g. 08:00 - 10:00',
              ),
              validator: (v) =>
                  Validators.required(v, fieldName: 'Arrival window'),
            ),
            const SizedBox(height: 32),

            // Navigation buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => notifier.prevStep(),
                    child: const Text('Back'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _proceed,
                    child: const Text('Next: Police Verification'),
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
