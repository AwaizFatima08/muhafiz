import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/themes.dart';
import '../../../core/enums/app_enums.dart';
import '../../../core/models/registration_request_model.dart';
import '../../../core/utils/validators.dart';
import '../../../providers/auth_provider.dart';

class ResidentWorkerRequestScreen extends ConsumerStatefulWidget {
  const ResidentWorkerRequestScreen({super.key});

  @override
  ConsumerState<ResidentWorkerRequestScreen> createState() =>
      _ResidentWorkerRequestScreenState();
}

class _ResidentWorkerRequestScreenState
    extends ConsumerState<ResidentWorkerRequestScreen> {
  final _formKey         = GlobalKey<FormState>();
  final _nameController  = TextEditingController();
  final _cnicController  = TextEditingController();
  final _houseController = TextEditingController();

  WorkerType _workerType           = WorkerType.houseMaid;
  NatureOfService _natureOfService = NatureOfService.dayCare;

  // C3 FIX: arrival window uses dropdowns (30-min slots) instead of
  // a free-text field — consistent with step2_employment_info.dart.
  String? _arrivalFrom;
  String? _arrivalTo;
  static final List<String> _timeSlots = List.generate(
    48,
    (i) => '${(i ~/ 2).toString().padLeft(2, '0')}:${i.isOdd ? '30' : '00'}',
  );

  bool _submitting = false;
  String? _error;
  String? _residentId;

  @override
  void initState() {
    super.initState();
    // C3 FIX: auto-fill house number from the logged-in resident's profile.
    _prefillHouse();
  }

  Future<void> _prefillHouse() async {
    final uid = ref.read(authStateProvider).valueOrNull?.uid;
    if (uid == null) return;
    final fs       = ref.read(firestoreServiceProvider);
    final resident = await fs.getResident(uid);
    if (resident != null && mounted) {
      setState(() {
        _residentId = uid;
        _houseController.text = resident.houseNumber;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cnicController.dispose();
    _houseController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _submitting = true; _error = null; });

    try {
      final fs          = ref.read(firestoreServiceProvider);
      final currentUser = ref.read(authStateProvider).valueOrNull;
      if (currentUser == null) throw Exception('Not logged in');

      // B1: use Validators.cleanCnic to strip dashes consistently
      final cleanCnic = Validators.cleanCnic(_cnicController.text);
      final existing  = await fs.getWorkerByCnic(cleanCnic);
      if (existing != null) {
        setState(() {
          _error      = 'This CNIC is already registered.';
          _submitting = false;
        });
        return;
      }

      final arrivalWindow = (_arrivalFrom != null && _arrivalTo != null)
          ? '$_arrivalFrom-$_arrivalTo'
          : '';

      // C3 FIX: write to registration_requests collection (not a separate
      // path) so supervisor dashboard watchPendingRequests() picks it up.
      final request = RegistrationRequestModel(
        id:          '',
        requestType: RegistrationRequestType.newWorker,
        residentId:  _residentId ?? currentUser.uid,
        submittedBy: currentUser.uid,
        initiatedBy: currentUser.uid,
        submittedAt: DateTime.now(),
        employeeData: {
          'worker_name':       _nameController.text.trim(),
          'cnic':              cleanCnic,
          'worker_type':       _workerType.name,
          'nature_of_service': _natureOfService.name,
          'house_number':      _houseController.text.trim().toUpperCase(),
          'arrival_window':    arrivalWindow,
          // Flag so clerk/supervisor knows this was resident-initiated
          'initiated_by_role': 'resident',
        },
        status: RegistrationRequestStatus.pending,
      );

      await fs.createRegistrationRequest(request);

      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Row(children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('Request Submitted'),
            ]),
            content: const Text(
              'Your worker registration request has been submitted.\n\n'
              'The gate clerk will contact the worker to complete '
              'document verification.',
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.pop();
                },
                child: const Text('Done'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error      = e.toString().replaceAll('Exception: ', '');
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Register Worker'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Worker Details',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text(
                      'Provide basic details. The gate clerk will '
                      'complete document verification.',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade500),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Worker Full Name *',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (v) =>
                          Validators.required(v, fieldName: 'Name'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _cnicController,
                      keyboardType: TextInputType.number,
                      maxLength: 13,
                      decoration: const InputDecoration(
                        labelText: 'CNIC *',
                        prefixIcon: Icon(Icons.badge_outlined),
                        hintText: '13 digits, no dashes',
                        counterText: '',
                      ),
                      validator: Validators.cnic,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<WorkerType>(
                      initialValue: _workerType,
                      decoration: const InputDecoration(
                        labelText: 'Worker Type *',
                        prefixIcon: Icon(Icons.work_outline),
                      ),
                      items: WorkerType.values
                          .map((t) => DropdownMenuItem(
                                value: t,
                                child: Text(
                                    '${t.name[0].toUpperCase()}${t.name.substring(1)}'),
                              ))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _workerType = v!),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<NatureOfService>(
                      initialValue: _natureOfService,
                      decoration: const InputDecoration(
                        labelText: 'Nature of Service *',
                        prefixIcon: Icon(Icons.schedule_outlined),
                      ),
                      items: NatureOfService.values
                          .map((t) => DropdownMenuItem(
                                value: t,
                                child: Text(
                                    '${t.name[0].toUpperCase()}${t.name.substring(1)}'),
                              ))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _natureOfService = v!),
                    ),
                    const SizedBox(height: 16),
                    // C3 FIX: house auto-filled from resident profile,
                    // still editable in case of correction.
                    TextFormField(
                      controller: _houseController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'House Number *',
                        prefixIcon: Icon(Icons.home_outlined),
                        hintText: 'e.g. BQ-12, A-150',
                        helperText: 'Auto-filled from your profile',
                      ),
                      validator: (v) =>
                          Validators.required(v, fieldName: 'House number'),
                    ),
                    const SizedBox(height: 16),
                    // C3 FIX: arrival window — 30-min slot dropdowns
                    // instead of free-text field.
                    const Text('Expected Arrival Window',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _arrivalFrom,
                          decoration: const InputDecoration(
                            labelText: 'From',
                            prefixIcon:
                                Icon(Icons.access_time_outlined),
                          ),
                          hint: const Text('--:--'),
                          items: _timeSlots
                              .map((t) => DropdownMenuItem(
                                    value: t,
                                    child: Text(t),
                                  ))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _arrivalFrom = v),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _arrivalTo,
                          decoration: const InputDecoration(
                            labelText: 'To',
                            prefixIcon:
                                Icon(Icons.access_time_outlined),
                          ),
                          hint: const Text('--:--'),
                          items: _timeSlots
                              .map((t) => DropdownMenuItem(
                                    value: t,
                                    child: Text(t),
                                  ))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _arrivalTo = v),
                        ),
                      ),
                    ]),
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
                          Expanded(
                              child: Text(_error!,
                                  style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 13))),
                        ]),
                      ),
                    ],
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitting ? null : _submit,
                        child: _submitting
                            ? const SizedBox(
                                height: 20, width: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white))
                            : const Text('Submit Request'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
