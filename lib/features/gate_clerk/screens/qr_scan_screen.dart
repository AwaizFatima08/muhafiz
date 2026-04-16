import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../config/themes.dart';
import '../../../core/models/worker_model.dart';
import '../../../core/models/worker_assignment_model.dart';
import '../../../core/enums/app_enums.dart';
import '../../../providers/auth_provider.dart';
import 'gate_event_handler.dart';

class QrScanScreen extends ConsumerStatefulWidget {
  const QrScanScreen({super.key});

  @override
  ConsumerState<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends ConsumerState<QrScanScreen> {
  MobileScannerController? _controller;
  bool _isProcessing = false;
  bool _torchOn = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;

    setState(() => _isProcessing = true);
    await _controller?.stop();

    final qrValue = barcode!.rawValue!;
    await _processQr(qrValue);
  }

  Future<void> _processQr(String qrValue) async {
    final firestoreService = ref.read(firestoreServiceProvider);
    final currentUser = ref.read(authStateProvider).valueOrNull;

    try {
      final worker = await firestoreService.getWorkerByQr(qrValue);

      if (!mounted) return;

      if (worker == null) {
        _showErrorDialog('Unknown QR Code',
            'No active worker found for this QR code.');
        return;
      }

      if (worker.status == WorkerStatus.suspended ||
          worker.status == WorkerStatus.blacklisted) {
        _showErrorDialog('Access Denied',
            'Worker \${worker.workerName} is \${worker.status.name}. Entry not permitted.');
        return;
      }

      if (worker.status != WorkerStatus.active) {
        _showErrorDialog('Not Active',
            'Worker \${worker.workerName} status is \${worker.status.name}.');
        return;
      }

      // Get assignment
      final assignment =
          await firestoreService.getActiveAssignmentForWorker(worker.id);
      final presence = await firestoreService.getPresence(worker.id);

      if (!mounted) return;

      // Show worker profile popup
      final result = await showModalBottomSheet<Map<String, dynamic>>(
        context: context,
        isScrollControlled: true,
        isDismissible: false,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) => WorkerGateProfileSheet(
          worker: worker,
          assignment: assignment,
          currentStatus: presence?.currentStatus ?? 'outside',
          processedBy: currentUser?.uid ?? '',
        ),
      );

      if (result != null && mounted) {
        // Process gate event
        await GateEventHandler.process(
          ref: ref,
          worker: worker,
          assignment: assignment,
          eventType: result['eventType'] as String,
          overrideReason: result['overrideReason'] as String?,
          processedBy: currentUser?.uid ?? '',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  "${result['eventType'] == 'entry' ? 'Entry' : 'Exit'} recorded for ${worker.workerName}"),
              backgroundColor: result['eventType'] == 'entry'
                  ? Colors.green
                  : Colors.orange,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        // Dismissed — restart scanner
        setState(() => _isProcessing = false);
        await _controller?.start();
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Error', e.toString());
      }
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: AppTheme.errorColor),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _isProcessing = false);
              _controller?.start();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_torchOn ? Icons.flash_on : Icons.flash_off),
            onPressed: () {
              _controller?.toggleTorch();
              setState(() => _torchOn = !_torchOn);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller!,
            onDetect: _onDetect,
          ),
          // Scan overlay
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  // Corner decorations
                  Positioned(top: 0, left: 0,
                      child: _Corner(color: AppTheme.primaryColor)),
                  Positioned(top: 0, right: 0,
                      child: Transform.rotate(angle: 1.5708,
                          child: _Corner(color: AppTheme.primaryColor))),
                  Positioned(bottom: 0, left: 0,
                      child: Transform.rotate(angle: -1.5708,
                          child: _Corner(color: AppTheme.primaryColor))),
                  Positioned(bottom: 0, right: 0,
                      child: Transform.rotate(angle: 3.14159,
                          child: _Corner(color: AppTheme.primaryColor))),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _isProcessing ? 'Processing...' : 'Align QR code within frame',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Corner extends StatelessWidget {
  final Color color;
  const _Corner({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 30,
      height: 30,
      child: CustomPaint(
        painter: _CornerPainter(color: color),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final Color color;
  _CornerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset.zero, Offset(size.width, 0), paint);
    canvas.drawLine(Offset.zero, Offset(0, size.height), paint);
  }

  @override
  bool shouldRepaint(_CornerPainter old) => old.color != color;
}

// Worker profile bottom sheet shown after scan
class WorkerGateProfileSheet extends StatefulWidget {
  final WorkerModel worker;
  final WorkerAssignmentModel? assignment;
  final String currentStatus;
  final String processedBy;

  const WorkerGateProfileSheet({
    super.key,
    required this.worker,
    required this.assignment,
    required this.currentStatus,
    required this.processedBy,
  });

  @override
  State<WorkerGateProfileSheet> createState() =>
      _WorkerGateProfileSheetState();
}

class _WorkerGateProfileSheetState extends State<WorkerGateProfileSheet> {
  final _overrideController = TextEditingController();
  bool _showOverride = false;

  @override
  void dispose() {
    _overrideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isInside = widget.currentStatus == 'inside';
    final suggestedEvent = isInside ? 'exit' : 'entry';
    final w = widget.worker;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20, right: 20, top: 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: isInside
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isInside
                      ? Colors.green.withValues(alpha: 0.4)
                      : Colors.grey.withValues(alpha: 0.4),
                ),
              ),
              child: Text(
                isInside ? 'Currently Inside' : 'Currently Outside',
                style: TextStyle(
                  color: isInside ? Colors.green : Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Worker info
            Row(
              children: [
                Container(
                  width: 60, height: 60,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person,
                      color: AppTheme.primaryColor, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(w.workerName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18)),
                      Text(w.cardNumber,
                          style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w500)),
                      Text('\${w.workerType.name} • \${w.natureOfService.name}',
                          style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),

            // Assignment info
            if (widget.assignment != null) ...[
              _InfoRow(Icons.home_outlined, 'House',
                  widget.assignment!.houseNumber),
              _InfoRow(Icons.access_time_outlined, 'Arrival Window',
                  widget.assignment!.arrivalWindow),
            ],
            _InfoRow(Icons.verified_user_outlined, 'Police Verified',
                w.policeVerified ? 'Yes' : 'No'),
            _InfoRow(Icons.badge_outlined, 'CNIC', w.cnic),

            // Warning flags
            if (isInside && suggestedEvent == 'entry') ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_outlined,
                        color: Colors.orange, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Worker is already marked as inside. Override required.',
                        style: TextStyle(
                            color: Colors.orange, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                value: _showOverride,
                onChanged: (v) =>
                    setState(() => _showOverride = v ?? false),
                title: const Text('Apply override',
                    style: TextStyle(fontSize: 13)),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
            ] else ...[
              const SizedBox(height: 8),
            ],

            if (_showOverride || (isInside && suggestedEvent == 'exit') || (!isInside && suggestedEvent == 'entry'))
              ...[],

            // Override reason field
            if (_showOverride) ...[
              TextFormField(
                controller: _overrideController,
                decoration: const InputDecoration(
                  labelText: 'Override Reason *',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
            ],

            const SizedBox(height: 8),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, null),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (_showOverride &&
                          _overrideController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Please enter override reason')),
                        );
                        return;
                      }
                      Navigator.pop(context, {
                        'eventType': suggestedEvent,
                        'overrideReason': _showOverride
                            ? _overrideController.text.trim()
                            : null,
                      });
                    },
                    icon: Icon(suggestedEvent == 'entry'
                        ? Icons.login_outlined
                        : Icons.logout_outlined),
                    label: Text(suggestedEvent == 'entry'
                        ? 'Confirm Entry'
                        : 'Confirm Exit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: suggestedEvent == 'entry'
                          ? Colors.green
                          : Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade500),
          const SizedBox(width: 8),
          SizedBox(
            width: 110,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13, color: Colors.grey)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
