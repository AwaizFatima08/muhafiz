import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../config/themes.dart';
import '../../../core/enums/app_enums.dart';
import '../../../providers/auth_provider.dart';

class GuestExitScreen extends ConsumerStatefulWidget {
  const GuestExitScreen({super.key});

  @override
  ConsumerState<GuestExitScreen> createState() => _GuestExitScreenState();
}

class _GuestExitScreenState extends ConsumerState<GuestExitScreen> {
  // C1 FIX: camera scanner only created on non-web platforms.
  // On web, MobileScanner is unavailable — show manual ID entry instead.
  MobileScannerController? _scanner;
  bool _processing  = false;
  String? _message;
  bool _success     = false;

  // C1 FIX: manual fallback state
  bool _showManual  = false;
  final _slipIdCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _scanner = MobileScannerController();
    }
  }

  @override
  void dispose() {
    _scanner?.dispose();
    _slipIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _processQr(String qrValue) async {
    if (_processing) return;
    setState(() { _processing = true; _message = null; });

    try {
      final fs    = ref.read(firestoreServiceProvider);
      final visit = await fs.getGuestVisitByQr(qrValue);

      if (visit == null) {
        setState(() {
          _message    = 'Slip not found or guest already exited.';
          _success    = false;
          _processing = false;
        });
        return;
      }

      if (DateTime.now().isAfter(visit.expiresAt)) {
        await fs.updateGuestVisit(visit.id, {
          'status':    GuestVisitStatus.expired.name,
          'exit_time': DateTime.now().toIso8601String(),
        });
        setState(() {
          _message    = 'Slip expired. Guest exit logged.';
          _success    = false;
          _processing = false;
        });
        return;
      }

      await fs.updateGuestVisit(visit.id, {
        'status':    GuestVisitStatus.exited.name,
        'exit_time': DateTime.now().toIso8601String(),
      });

      setState(() {
        _message    = 'Exit logged for ${visit.visitorName}.';
        _success    = true;
        _processing = false;
      });

      await Future.delayed(const Duration(seconds: 2));
      if (mounted) Navigator.pop(context);

    } catch (e) {
      setState(() {
        _message    = 'Error: ${e.toString().replaceAll('Exception: ', '')}';
        _success    = false;
        _processing = false;
      });
    }
  }

  // C1 FIX: manual entry submit — clerk types the slip QR value
  // (printed on the slip as "Slip ID") when QR scan is not possible.
  Future<void> _submitManual() async {
    final value = _slipIdCtrl.text.trim().toUpperCase();
    if (value.isEmpty) return;
    await _processQr(value);
  }

  @override
  Widget build(BuildContext context) {
    // C1 FIX: on web, skip the camera entirely and show manual entry.
    if (kIsWeb || _showManual) {
      return _buildManualEntry();
    }
    return _buildScanner();
  }

  Widget _buildScanner() {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Guest Exit — Scan Slip'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        // C1 FIX: action button to switch to manual entry fallback.
        actions: [
          TextButton.icon(
            onPressed: () => setState(() => _showManual = true),
            icon: const Icon(Icons.keyboard_outlined,
                color: Colors.white, size: 18),
            label: const Text('Manual',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _scanner!,
            onDetect: (capture) {
              final barcode = capture.barcodes.firstOrNull;
              if (barcode?.rawValue != null) {
                _processQr(barcode!.rawValue!);
              }
            },
          ),
          // Scan frame overlay
          Center(
            child: Container(
              width: 240, height: 240,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          // Status message
          if (_message != null)
            Positioned(
              bottom: 60, left: 20, right: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _success
                      ? Colors.green.withValues(alpha: 0.9)
                      : Colors.red.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(children: [
                  Icon(
                    _success
                        ? Icons.check_circle
                        : Icons.error_outline,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(_message!,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500)),
                  ),
                ]),
              ),
            ),
          if (_processing)
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          Positioned(
            bottom: 20, left: 0, right: 0,
            child: Center(
              child: Text(
                'Scan the QR code on the guest slip',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // C1 FIX: manual slip ID entry screen — used on web and as
  // fallback when QR code cannot be scanned (torn/wet slip).
  Widget _buildManualEntry() {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Guest Exit — Manual'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        // Show "Scan" button to go back to camera on mobile
        actions: [
          if (!kIsWeb)
            TextButton.icon(
              onPressed: () => setState(() => _showManual = false),
              icon: const Icon(Icons.qr_code_scanner,
                  color: Colors.white, size: 18),
              label: const Text('Scan QR',
                  style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter Slip ID',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(
              'The Slip ID is printed on the guest entry slip '
              'below the QR code.',
              style: TextStyle(
                  fontSize: 12, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _slipIdCtrl,
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submitManual(),
              decoration: const InputDecoration(
                labelText: 'Slip ID *',
                prefixIcon: Icon(Icons.confirmation_number_outlined),
                hintText: 'e.g. GV-A1B2C3D4',
              ),
            ),
            if (_message != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _success
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _success
                        ? Colors.green.withValues(alpha: 0.3)
                        : Colors.red.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(children: [
                  Icon(
                    _success
                        ? Icons.check_circle_outline
                        : Icons.error_outline,
                    color: _success ? Colors.green : Colors.red,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_message!,
                        style: TextStyle(
                            color:
                                _success ? Colors.green : Colors.red,
                            fontSize: 13)),
                  ),
                ]),
              ),
            ],
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _processing ? null : _submitManual,
                icon: _processing
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.logout_outlined),
                label: const Text('Process Exit'),
                style: ElevatedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(vertical: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
