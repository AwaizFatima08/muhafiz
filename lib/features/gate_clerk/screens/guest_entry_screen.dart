import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../config/themes.dart';
import '../../../core/enums/app_enums.dart';
import '../../../core/models/guest_visit_model.dart';
import '../../../core/models/site_settings_model.dart';
import '../../../core/services/guest_slip_pdf_service.dart';
import '../../../core/utils/validators.dart';
import '../../../providers/auth_provider.dart';

const _purposeOptions = [
  'Family Visit',
  'Official Business',
  'Vendor',
  'Other',
];

class GuestEntryScreen extends ConsumerStatefulWidget {
  const GuestEntryScreen({super.key});

  @override
  ConsumerState<GuestEntryScreen> createState() => _GuestEntryScreenState();
}

class _GuestEntryScreenState extends ConsumerState<GuestEntryScreen> {
  final _formKey          = GlobalKey<FormState>();
  final _visitorNameCtrl  = TextEditingController();
  final _visitorCnicCtrl  = TextEditingController();
  final _vehiclePlateCtrl = TextEditingController();
  final _residentNameCtrl = TextEditingController();
  final _houseCtrl        = TextEditingController();
  final _empNoCtrl        = TextEditingController();

  String _selectedPurpose = _purposeOptions[0];
  bool _submitting        = false;
  String? _error;

  // Resident lookup state
  bool _lookingUp    = false;
  String? _residentId;
  String? _residentEmpNo;

  @override
  void dispose() {
    for (final c in [
      _visitorNameCtrl, _visitorCnicCtrl, _vehiclePlateCtrl,
      _residentNameCtrl, _houseCtrl, _empNoCtrl,
    ]) { c.dispose(); }
    super.dispose();
  }

  Future<void> _lookupResident() async {
    final house = _houseCtrl.text.trim().toUpperCase();
    final empNo = _empNoCtrl.text.trim();
    if (house.isEmpty && empNo.isEmpty) return;

    setState(() { _lookingUp = true; _error = null; });
    try {
      final fs   = ref.read(firestoreServiceProvider);
      final snap = house.isNotEmpty
          ? await fs.residentByHouseNumber(house)
          : await fs.residentByEmployeeNumber(empNo);

      if (snap != null && mounted) {
        setState(() {
          _residentId    = snap.id;
          _residentEmpNo = snap.residentNumber ?? snap.employeeNumber;
          _residentNameCtrl.text = snap.name;
          if (house.isEmpty) _houseCtrl.text = snap.houseNumber;
          if (empNo.isEmpty && _residentEmpNo != null) {
            _empNoCtrl.text = _residentEmpNo!;
          }
        });
      } else if (mounted) {
        setState(() => _error = 'Resident not found.');
      }
    } finally {
      if (mounted) setState(() => _lookingUp = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _submitting = true; _error = null; });

    try {
      final fs          = ref.read(firestoreServiceProvider);
      final currentUser = ref.read(authStateProvider).valueOrNull;
      if (currentUser == null) throw Exception('Not logged in');

      final now       = DateTime.now();
      final expiresAt = now.add(const Duration(hours: 24));
      final qrValue   =
          'GV-${const Uuid().v4().substring(0, 8).toUpperCase()}';

      // B1 FIX: cleanCnic strips any dashes the clerk typed before storage
      final cnicClean = Validators.cleanCnic(_visitorCnicCtrl.text);

      final visit = GuestVisitModel(
        id:                       '',
        visitorName:              _visitorNameCtrl.text.trim(),
        visitorCnic:              cnicClean,
        visitingResidentId:       _residentId ?? '',
        residentName:             _residentNameCtrl.text.trim(),
        residentEmployeeNumber:   _residentEmpNo,
        houseNumber:              _houseCtrl.text.trim().toUpperCase(),
        purpose:                  _selectedPurpose,
        vehicleRegistrationNumber: _vehiclePlateCtrl.text.trim().isEmpty
            ? null
            : _vehiclePlateCtrl.text.trim().toUpperCase(),
        entryTime:   now,
        expiresAt:   expiresAt,
        slipQrValue: qrValue,
        status:      GuestVisitStatus.inside,
        gateClerkId: currentUser.uid,
      );

      final visitId    = await fs.createGuestVisit(visit);
      final savedVisit = GuestVisitModel(
        id:                       visitId,
        visitorName:              visit.visitorName,
        visitorCnic:              visit.visitorCnic,
        visitingResidentId:       visit.visitingResidentId,
        residentName:             visit.residentName,
        residentEmployeeNumber:   visit.residentEmployeeNumber,
        houseNumber:              visit.houseNumber,
        purpose:                  visit.purpose,
        vehicleRegistrationNumber: visit.vehicleRegistrationNumber,
        entryTime:   visit.entryTime,
        expiresAt:   visit.expiresAt,
        slipQrValue: visit.slipQrValue,
        status:      visit.status,
        gateClerkId: visit.gateClerkId,
      );

      final settings = await fs.getSiteSettings('township_main') ??
          SiteSettings(
            siteId:   'township_main',
            siteName: 'FFL Township',
            overstayThresholdHours: 8,
          );

      final pdfBytes = await GuestSlipPdfService.generate(
        visit:     savedVisit,
        settings:  settings,
        clerkName: currentUser.uid,
      );

      setState(() => _submitting = false);

      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Row(children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('Guest Logged'),
            ]),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Visitor: ${savedVisit.visitorName}'),
                Text('House: ${savedVisit.houseNumber}'),
                const SizedBox(height: 8),
                Text(
                  'Valid until: ${savedVisit.expiresAt.day}/'
                  '${savedVisit.expiresAt.month} '
                  '${savedVisit.expiresAt.hour.toString().padLeft(2, "0")}:'
                  '${savedVisit.expiresAt.minute.toString().padLeft(2, "0")}',
                  style: const TextStyle(color: Colors.red),
                ),
              ],
            ),
            actions: [
              OutlinedButton.icon(
                icon: const Icon(Icons.share_outlined, size: 18),
                label: const Text('Share PDF'),
                onPressed: () =>
                    GuestSlipPdfService.sharePdf(pdfBytes, savedVisit.id),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.print_outlined, size: 18),
                label: const Text('Print Slip'),
                onPressed: () => GuestSlipPdfService.printSlip(pdfBytes),
              ),
              TextButton(
                onPressed: () {
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
        title: const Text('Guest Entry'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Resident lookup ────────────────────────────────────
              const Text('Resident',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Text(
                'Search by employee number or house number',
                style: TextStyle(
                    fontSize: 12, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: TextFormField(
                    controller: _empNoCtrl,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Employee Number',
                      prefixIcon: Icon(Icons.badge_outlined),
                      hintText: 'FFL-00123',
                    ),
                    onFieldSubmitted: (_) => _lookupResident(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _houseCtrl,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'House Number',
                      prefixIcon: Icon(Icons.home_outlined),
                      hintText: 'BQ-12',
                    ),
                    onFieldSubmitted: (_) => _lookupResident(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _lookingUp ? null : _lookupResident,
                  icon: _lookingUp
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.search),
                  style: IconButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor),
                ),
              ]),
              const SizedBox(height: 12),
              TextFormField(
                controller: _residentNameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Resident Name *',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) =>
                    Validators.required(v, fieldName: 'Resident name'),
              ),
              const SizedBox(height: 20),

              // ── Visitor details ────────────────────────────────────
              const Text('Visitor',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _visitorNameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Visitor Name *',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                validator: (v) =>
                    Validators.required(v, fieldName: 'Visitor name'),
              ),
              const SizedBox(height: 12),
              // B1 FIX: CNIC field uses Validators.cnic (13 digits, no
              // dashes) — hint text updated to match storage format.
              TextFormField(
                controller: _visitorCnicCtrl,
                keyboardType: TextInputType.number,
                maxLength: 13,
                decoration: const InputDecoration(
                  labelText: 'CNIC *',
                  prefixIcon: Icon(Icons.credit_card_outlined),
                  hintText: '13 digits, no dashes',
                  counterText: '',
                ),
                validator: Validators.cnic,
              ),
              const SizedBox(height: 12),
              // B1 FIX: purpose dropdown uses initialValue (not value)
              // to resolve the deprecated_member_use warning.
              DropdownButtonFormField<String>(
                initialValue: _selectedPurpose,
                decoration: const InputDecoration(
                  labelText: 'Purpose *',
                  prefixIcon: Icon(Icons.info_outline),
                ),
                items: _purposeOptions
                    .map((p) =>
                        DropdownMenuItem(value: p, child: Text(p)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedPurpose = v!),
                validator: (v) => v == null ? 'Select a purpose' : null,
              ),
              const SizedBox(height: 12),
              // C2 FIX: vehicle is optional — not all guests arrive
              // by car (pedestrians, cyclists). Validator only runs
              // when the field is non-empty.
              TextFormField(
                controller: _vehiclePlateCtrl,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Vehicle Registration',
                  prefixIcon: Icon(Icons.directions_car_outlined),
                  hintText: 'ABC-1234 (optional)',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  return Validators.vehiclePlate(v);
                },
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
                    Expanded(
                        child: Text(_error!,
                            style: const TextStyle(
                                color: Colors.red, fontSize: 13))),
                  ]),
                ),
              ],

              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _submitting ? null : _submit,
                  icon: _submitting
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.how_to_reg_outlined),
                  label: const Text('Log Guest & Print Slip'),
                  style: ElevatedButton.styleFrom(
                      padding:
                          const EdgeInsets.symmetric(vertical: 14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
