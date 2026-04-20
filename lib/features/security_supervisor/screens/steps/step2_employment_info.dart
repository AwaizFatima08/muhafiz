import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/validators.dart';
import '../../../../providers/registration_form_provider.dart';
import '../../../../providers/auth_provider.dart';

class Step2EmploymentInfo extends ConsumerStatefulWidget {
  const Step2EmploymentInfo({super.key});

  @override
  ConsumerState<Step2EmploymentInfo> createState() =>
      _Step2EmploymentInfoState();
}

class _Step2EmploymentInfoState
    extends ConsumerState<Step2EmploymentInfo> {
  final _formKey        = GlobalKey<FormState>();
  final _houseController = TextEditingController();

  // A2 FIX: removed dead _arrivalController — never used in original.
  String? _selectedResidentId;
  bool _loadingResidents = true;

  String? _arrivalFrom;
  String? _arrivalTo;

  // 30-minute time slots for the full 24-hour day
  static final List<String> _timeSlots = List.generate(
    48,
    (i) =>
        '${(i ~/ 2).toString().padLeft(2, '0')}:${i.isOdd ? '30' : '00'}',
  );

  // A2 FIX: each entry holds id, name, and houseNumber (not .unit which
  // doesn't exist on ResidentModel).
  List<Map<String, String>> _residents = [];

  @override
  void initState() {
    super.initState();
    final state = ref.read(registrationFormProvider);
    _houseController.text = state.houseNumber;

    // Restore arrival window stored as 'HH:MM-HH:MM'
    final parts = state.arrivalWindow.split('-');
    _arrivalFrom =
        parts.isNotEmpty && parts[0].isNotEmpty ? parts[0] : null;
    _arrivalTo =
        parts.length > 1 && parts[1].isNotEmpty ? parts[1] : null;
    _selectedResidentId =
        state.residentId.isEmpty ? null : state.residentId;

    _loadResidents();
  }

  Future<void> _loadResidents() async {
    final fs = ref.read(firestoreServiceProvider);
    // A2 FIX: use watchActiveResidents().first — correct collection.
    // Map to id + name + houseNumber (houseNumber is the correct field,
    // ResidentModel has no .unit property).
    final residents = await fs.watchActiveResidents().first;
    if (mounted) {
      setState(() {
        _residents = residents
            .map((r) => {
                  'id':    r.id,
                  'name':  r.name,
                  'house': r.houseNumber,
                })
            .toList();
        _loadingResidents = false;

        // Auto-fill house number if a resident was already selected
        // (e.g. navigating back from step 3).
        if (_selectedResidentId != null) {
          final match = _residents
              .where((r) => r['id'] == _selectedResidentId)
              .firstOrNull;
          if (match != null && _houseController.text.isEmpty) {
            _houseController.text = match['house'] ?? '';
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _houseController.dispose();
    super.dispose();
  }

  void _onResidentChanged(String? residentId) {
    setState(() {
      _selectedResidentId = residentId;
      // A2 FIX: auto-fill house number when a resident is selected so the
      // clerk doesn't have to type it manually (avoids house/resident mismatch).
      if (residentId != null) {
        final match =
            _residents.where((r) => r['id'] == residentId).firstOrNull;
        if (match != null) {
          _houseController.text = match['house'] ?? '';
        }
      }
    });
  }

  void _proceed() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedResidentId == null) return;

    final notifier = ref.read(registrationFormProvider.notifier);
    notifier.updateStep2(
      residentId:    _selectedResidentId,
      houseNumber:   _houseController.text.trim(),
      arrivalWindow: '${_arrivalFrom ?? ''}-${_arrivalTo ?? ''}',
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
            Text(
              'Employment Details',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Resident / Employer selector
            _loadingResidents
                ? const Center(child: CircularProgressIndicator())
                : DropdownButtonFormField<String>(
                    initialValue: _selectedResidentId,
                    decoration: const InputDecoration(
                      // A2 FIX: label updated to "Resident / Employer"
                      // — matches the architecture rule that residents
                      //   collection replaces employers everywhere.
                      labelText: 'Resident / Employer *',
                      prefixIcon: Icon(Icons.home_outlined),
                    ),
                    hint: const Text('Select resident'),
                    items: _residents.map((r) {
                      return DropdownMenuItem<String>(
                        value: r['id'],
                        child: Text('${r["name"]} — ${r["house"]}'),
                      );
                    }).toList(),
                    onChanged: _onResidentChanged,
                    validator: (v) =>
                        v == null ? 'Please select a resident' : null,
                  ),
            const SizedBox(height: 16),

            // House number — auto-filled when resident selected, editable
            TextFormField(
              controller: _houseController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'House Number *',
                prefixIcon: Icon(Icons.house_outlined),
                hintText: 'e.g. A-123',
                helperText: 'Auto-filled from selected resident',
              ),
              validator: (v) =>
                  Validators.required(v, fieldName: 'House number'),
            ),
            const SizedBox(height: 16),

            // Arrival window — from/to dropdowns in 30-min slots
            Row(children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _arrivalFrom,
                  decoration: const InputDecoration(
                    labelText: 'From *',
                    prefixIcon: Icon(Icons.access_time_outlined),
                  ),
                  items: _timeSlots
                      .map((t) => DropdownMenuItem(
                            value: t,
                            child: Text(t),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _arrivalFrom = v),
                  validator: (v) =>
                      v == null ? 'Select from time' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _arrivalTo,
                  decoration: const InputDecoration(
                    labelText: 'To *',
                    prefixIcon: Icon(Icons.access_time_outlined),
                  ),
                  items: _timeSlots
                      .map((t) => DropdownMenuItem(
                            value: t,
                            child: Text(t),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _arrivalTo = v),
                  validator: (v) =>
                      v == null ? 'Select to time' : null,
                ),
              ),
            ]),
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
