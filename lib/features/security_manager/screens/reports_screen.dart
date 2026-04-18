import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import '../../../core/services/report_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _reportService = ReportService();
  DateTime _selectedDate = DateTime.now();
  bool _isGenerating = false;
  String? _lastFilePath;
  String? _lastReportName;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _generate(
      String reportName, Future<String> Function() generator) async {
    setState(() {
      _isGenerating = true;
      _lastFilePath = null;
      _lastReportName = null;
    });

    try {
      final path = await generator();
      setState(() {
        _lastFilePath = path;
        _lastReportName = reportName;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$reportName saved to Downloads'),
            action: SnackBarAction(
              label: 'Open',
              onPressed: () => OpenFile.open(path),
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _share() async {
    if (_lastFilePath == null || _lastReportName == null) return;
    await _reportService.shareFile(_lastFilePath!, _lastReportName!);
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd MMMM yyyy').format(_selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
      ),
      body: _isGenerating
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Generating report...'),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Last generated ──
                if (_lastFilePath != null) ...[
                  Card(
                    color: Colors.green.shade50,
                    child: ListTile(
                      leading:
                          const Icon(Icons.check_circle, color: Colors.green),
                      title: Text(_lastReportName ?? 'Report ready'),
                      subtitle: const Text('Saved to Downloads'),
                      trailing: IconButton(
                        icon: const Icon(Icons.share),
                        onPressed: _share,
                        tooltip: 'Share',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Report 1: Daily Gate Log ──
                _ReportCard(
                  icon: Icons.list_alt,
                  title: 'Daily Gate Log',
                  description:
                      'All entry/exit events for a selected date. Includes worker name, card number, method, and timestamp.',
                  color: Colors.blue,
                  dateSelector: GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blue.shade200),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.blue.shade50,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.calendar_today,
                              size: 16, color: Colors.blue),
                          const SizedBox(width: 6),
                          Text(dateStr,
                              style:
                                  const TextStyle(color: Colors.blue)),
                        ],
                      ),
                    ),
                  ),
                  onGenerate: () => _generate(
                    'Daily Gate Log — $dateStr',
                    () => _reportService.generateDailyGateLog(_selectedDate),
                  ),
                ),

                const SizedBox(height: 12),

                // ── Report 2: Presence Snapshot ──
                _ReportCard(
                  icon: Icons.people_alt,
                  title: 'Presence Snapshot',
                  description:
                      'All workers currently inside the township at this moment, sorted by time inside.',
                  color: Colors.orange,
                  onGenerate: () => _generate(
                    'Presence Snapshot',
                    () => _reportService.generatePresenceSnapshot(),
                  ),
                ),

                const SizedBox(height: 12),

                // ── Report 3: Worker Registry ──
                _ReportCard(
                  icon: Icons.badge,
                  title: 'Worker Registry',
                  description:
                      'All active and suspended workers with CNIC, card number, worker type, and police verification status.',
                  color: Colors.green,
                  onGenerate: () => _generate(
                    'Worker Registry',
                    () => _reportService.generateWorkerRegistry(),
                  ),
                ),

                const SizedBox(height: 12),

                // ── Report 4: Guest Visit Log ──
                _ReportCard(
                  icon: Icons.person_pin_outlined,
                  title: 'Guest Visit Log',
                  description:
                      'All guest visits for selected date with visitor name, CNIC, house, purpose, entry/exit times.',
                  color: Colors.purple,
                  dateSelector: GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: Colors.purple.shade200),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.purple.shade50,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.calendar_today,
                              size: 16,
                              color: Colors.purple.shade700),
                          const SizedBox(width: 6),
                          Text(dateStr,
                              style: TextStyle(
                                  color: Colors.purple.shade700)),
                        ],
                      ),
                    ),
                  ),
                  onGenerate: () => _generate(
                    'Guest Visit Log — \$dateStr',
                    () => _reportService
                        .generateGuestVisitLog(_selectedDate),
                  ),
                ),

                const SizedBox(height: 12),

                // ── Report 5: Vehicle Log ──
                _ReportCard(
                  icon: Icons.directions_car_outlined,
                  title: 'Vehicle Gate Log',
                  description:
                      'All vehicle entry/exit events for selected date.',
                  color: Colors.amber.shade700,
                  dateSelector: GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: Colors.amber.shade200),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.amber.shade50,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.calendar_today,
                              size: 16,
                              color: Colors.amber.shade800),
                          const SizedBox(width: 6),
                          Text(dateStr,
                              style: TextStyle(
                                  color: Colors.amber.shade800)),
                        ],
                      ),
                    ),
                  ),
                  onGenerate: () => _generate(
                    'Vehicle Gate Log — \$dateStr',
                    () => _reportService
                        .generateVehicleLog(_selectedDate),
                  ),
                ),

                const SizedBox(height: 12),

                // ── Report 6: Resident Registry ──
                _ReportCard(
                  icon: Icons.home_outlined,
                  title: 'Resident Registry',
                  description:
                      'All approved residents with house number, contact, organisation.',
                  color: Colors.teal,
                  onGenerate: () => _generate(
                    'Resident Registry',
                    () => _reportService.generateResidentRegistry(),
                  ),
                ),

                const SizedBox(height: 12),

                // ── Report 7: Card Expiry Alerts ──
                _ReportCard(
                  icon: Icons.credit_card_off_outlined,
                  title: 'Card Expiry Alerts',
                  description:
                      'Workers whose cards expire within 30 days.',
                  color: Colors.orange,
                  onGenerate: () => _generate(
                    'Card Expiry Alerts',
                    () => _reportService.generateCardExpiryAlerts(),
                  ),
                ),

                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 8),

                // ── Emergency Muster ──
                Card(
                  color: Colors.red.shade50,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                        color: Colors.red.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          CircleAvatar(
                            backgroundColor:
                                Colors.red.withValues(alpha: 0.15),
                            child: const Icon(
                                Icons.emergency_outlined,
                                color: Colors.red),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text('Emergency Muster',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.red)),
                          ),
                        ]),
                        const SizedBox(height: 8),
                        Text(
                          'Instant Excel export of ALL people currently inside — workers, guests, and vehicles.',
                          style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 13),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(
                                Icons.download_outlined),
                            label: const Text(
                                'Generate Muster Now'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () => _generate(
                              'Emergency Muster',
                              () => _reportService
                                  .generateEmergencyMuster(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final Widget? dateSelector;
  final VoidCallback onGenerate;

  const _ReportCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onGenerate,
    this.dateSelector,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.15),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(description,
                style: TextStyle(
                    color: Colors.grey.shade600, fontSize: 13)),
            if (dateSelector != null) ...[
              const SizedBox(height: 10),
              dateSelector!,
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.download),
                label: const Text('Generate & Save'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                ),
                onPressed: onGenerate,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

