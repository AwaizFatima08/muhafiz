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
  final MobileScannerController _scanner = MobileScannerController();
  bool _processing = false;
  String? _message;
  bool _success = false;

  @override
  void dispose() {
    _scanner.dispose();
    super.dispose();
  }

  Future<void> _processQr(String qrValue) async {
    if (_processing) return;
    setState(() { _processing = true; _message = null; });

    try {
      final fs = ref.read(firestoreServiceProvider);
      final visit = await fs.getGuestVisitByQr(qrValue);

      if (visit == null) {
        setState(() {
          _message  = 'Slip not found or guest already exited.';
          _success  = false;
          _processing = false;
        });
        return;
      }

      // Check expiry
      if (DateTime.now().isAfter(visit.expiresAt)) {
        await fs.updateGuestVisit(visit.id, {
          'status': GuestVisitStatus.expired.name,
          'exit_time': DateTime.now().toIso8601String(),
        });
        setState(() {
          _message  = 'Slip expired. Guest exit logged.';
          _success  = false;
          _processing = false;
        });
        return;
      }

      // Auto exit
      await fs.updateGuestVisit(visit.id, {
        'status':    GuestVisitStatus.exited.name,
        'exit_time': DateTime.now().toIso8601String(),
      });

      setState(() {
        _message  = 'Exit logged for \${visit.visitorName}.';
        _success  = true;
        _processing = false;
      });

      // Auto-close after 2 seconds
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) Navigator.pop(context);

    } catch (e) {
      setState(() {
        _message  = 'Error: \$e';
        _success  = false;
        _processing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Guest Exit — Scan Slip'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _scanner,
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
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          // Status message
          if (_message != null)
            Positioned(
              bottom: 60,
              left: 20,
              right: 20,
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
                    _success ? Icons.check_circle : Icons.error_outline,
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
          // Hint
          Positioned(
            bottom: 20,
            left: 0, right: 0,
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
}
