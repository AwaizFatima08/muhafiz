import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ReportService {
  final FirebaseFirestore _db;

  ReportService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  // ─── Date helpers ────────────────────────────────────────────────────────

  DateTime _startOfDay(DateTime d) =>
      DateTime(d.year, d.month, d.day, 0, 0, 0);

  DateTime _endOfDay(DateTime d) =>
      DateTime(d.year, d.month, d.day, 23, 59, 59);

  String _fmt(DateTime? dt) {
    if (dt == null) return '—';
    return DateFormat('dd/MM/yyyy HH:mm').format(dt);
  }


  // ─── Style helpers ───────────────────────────────────────────────────────

  CellStyle _headerStyle() => CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#1E3A5F'),
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );

  CellStyle _subHeaderStyle() => CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#2E86AB'),
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        horizontalAlign: HorizontalAlign.Center,
      );

  CellStyle _altRowStyle() => CellStyle(
        backgroundColorHex: ExcelColor.fromHexString('#F0F4F8'),
      );

  CellStyle _entryStyle() => CellStyle(
        fontColorHex: ExcelColor.fromHexString('#1A7A1A'),
        bold: true,
      );

  CellStyle _exitStyle() => CellStyle(
        fontColorHex: ExcelColor.fromHexString('#B30000'),
        bold: true,
      );

  void _setCell(Sheet sheet, int row, int col, dynamic value,
      {CellStyle? style}) {
    final cell = sheet.cell(CellIndex.indexByColumnRow(
        columnIndex: col, rowIndex: row));
    if (value is int) {
      cell.value = IntCellValue(value);
    } else if (value is double) {
      cell.value = DoubleCellValue(value);
    } else {
      cell.value = TextCellValue(value?.toString() ?? '');
    }
    if (style != null) cell.cellStyle = style;
  }

  void _setColWidth(Sheet sheet, int col, double width) {
    sheet.setColumnWidth(col, width);
  }

  // ─── Save & Share ────────────────────────────────────────────────────────

  Future<String> _saveFile(Excel excel, String fileName) async {
    final bytes = excel.save();
    if (bytes == null) throw Exception('Failed to encode Excel file');

    Directory dir;
    if (Platform.isAndroid) {
      // Save to Downloads on Android
      dir = Directory('/storage/emulated/0/Download');
      if (!await dir.exists()) {
        dir = await getApplicationDocumentsDirectory();
      }
    } else {
      dir = await getApplicationDocumentsDirectory();
    }

    final filePath = '${dir.path}/$fileName';
    final file = File(filePath);
    await file.writeAsBytes(bytes);
    return filePath;
  }

  Future<void> shareFile(String filePath, String subject) async {
    await Share.shareXFiles(
      [XFile(filePath)],
      subject: subject,
      text: 'Muhafiz Report — $subject',
    );
  }

  // ─── Report 1: Daily Gate Log ─────────────────────────────────────────────

  Future<String> generateDailyGateLog(DateTime date) async {
    final start = Timestamp.fromDate(_startOfDay(date));
    final end = Timestamp.fromDate(_endOfDay(date));

    final snap = await _db
        .collection('gate_events')
        .where('processed_at', isGreaterThanOrEqualTo: start)
        .where('processed_at', isLessThanOrEqualTo: end)
        .orderBy('processed_at', descending: false)
        .get();

    // Fetch worker names in parallel
    final workerIds =
        snap.docs.map((d) => d['workerId'] as String? ?? '').toSet();
    final workerNames = <String, String>{};
    await Future.wait(workerIds.map((id) async {
      if (id.isEmpty) return;
      final doc = await _db.collection('workers').doc(id).get();
      if (doc.exists) {
        final data = doc.data()!;
        workerNames[id] =
            data['worker_name'] ?? data['name'] ?? 'Unknown';
      }
    }));

    final excel = Excel.createExcel();
    final sheet = excel['Gate Log'];
    excel.delete('Sheet1');

    final dateStr = DateFormat('dd MMMM yyyy').format(date);

    // Title row
    _setCell(sheet, 0, 0, 'MUHAFIZ — DAILY GATE LOG', style: _headerStyle());
    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
        CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: 0));

    // Date row
    _setCell(sheet, 1, 0, 'Date: $dateStr', style: _subHeaderStyle());
    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1),
        CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: 1));

    // Summary row
    final entries =
        snap.docs.where((d) => d['event_type'] == 'entry').length;
    final exits =
        snap.docs.where((d) => d['event_type'] == 'exit').length;
    _setCell(sheet, 2, 0,
        'Total Events: ${snap.docs.length}   |   Entries: $entries   |   Exits: $exits',
        style: _subHeaderStyle());
    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2),
        CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: 2));

    // Column headers
    final headers = [
      '#', 'Worker Name', 'Card Number', 'Event', 'Method',
      'Processed By', 'Time'
    ];
    for (var i = 0; i < headers.length; i++) {
      _setCell(sheet, 3, i, headers[i], style: _subHeaderStyle());
    }

    // Data rows
    for (var i = 0; i < snap.docs.length; i++) {
      final d = snap.docs[i].data();
      final workerId = d['workerId'] as String? ?? '';
      final eventType = d['event_type'] as String? ?? '';
      final time = d['processed_at'] != null
          ? _fmt((d['processed_at'] as Timestamp).toDate())
          : '—';
      final style = i.isOdd
          ? _altRowStyle()
          : null;
      final eventStyle =
          eventType == 'entry' ? _entryStyle() : _exitStyle();

      _setCell(sheet, i + 4, 0, i + 1, style: style);
      _setCell(sheet, i + 4, 1, workerNames[workerId] ?? 'Unknown',
          style: style);
      _setCell(sheet, i + 4, 2, d['card_number'] ?? '—', style: style);
      _setCell(sheet, i + 4, 3, eventType.toUpperCase(),
          style: eventStyle);
      _setCell(sheet, i + 4, 4, d['method'] ?? '—', style: style);
      _setCell(sheet, i + 4, 5, d['processed_by'] ?? '—', style: style);
      _setCell(sheet, i + 4, 6, time, style: style);
    }

    // Column widths
    _setColWidth(sheet, 0, 5);
    _setColWidth(sheet, 1, 25);
    _setColWidth(sheet, 2, 18);
    _setColWidth(sheet, 3, 10);
    _setColWidth(sheet, 4, 12);
    _setColWidth(sheet, 5, 22);
    _setColWidth(sheet, 6, 20);

    final fileName =
        'Muhafiz_GateLog_${DateFormat('yyyy-MM-dd').format(date)}.xlsx';
    return await _saveFile(excel, fileName);
  }

  // ─── Report 2: Presence Snapshot ─────────────────────────────────────────

  Future<String> generatePresenceSnapshot() async {
    final snap = await _db
        .collection('presence_tracker')
        .where('current_status', isEqualTo: 'inside')
        .get();

    // Fetch full worker details
    final rows = <Map<String, dynamic>>[];
    await Future.wait(snap.docs.map((doc) async {
      final data = doc.data();
      final workerId = doc.id;
      final workerDoc =
          await _db.collection('workers').doc(workerId).get();
      String workerName = data['worker_name'] ?? 'Unknown';
      String cardNumber = data['card_number'] ?? '—';
      String cnic = '—';
      if (workerDoc.exists) {
        final wd = workerDoc.data()!;
        workerName = wd['worker_name'] ?? wd['name'] ?? workerName;
        cardNumber = wd['card_number'] ?? cardNumber;
        cnic = wd['cnic'] ?? '—';
      }
      final entryTime = data['last_event_time'] != null
          ? (data['last_event_time'] as Timestamp).toDate()
          : null;
      final duration = entryTime != null
          ? DateTime.now().difference(entryTime)
          : null;
      final durationStr = duration != null
          ? '${duration.inHours}h ${duration.inMinutes % 60}m'
          : '—';

      rows.add({
        'worker_name': workerName,
        'card_number': cardNumber,
        'cnic': cnic,
        'entry_time': _fmt(entryTime),
        'duration': durationStr,
        'duration_minutes': duration?.inMinutes ?? 0,
      });
    }));

    // Sort by duration descending (longest inside first)
    rows.sort((a, b) =>
        (b['duration_minutes'] as int).compareTo(a['duration_minutes'] as int));

    final excel = Excel.createExcel();
    final sheet = excel['Presence Snapshot'];
    excel.delete('Sheet1');

    final now = DateTime.now();
    final nowStr = DateFormat('dd MMMM yyyy HH:mm').format(now);

    // Title
    _setCell(sheet, 0, 0, 'MUHAFIZ — PRESENCE SNAPSHOT',
        style: _headerStyle());
    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
        CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: 0));

    // Timestamp
    _setCell(sheet, 1, 0, 'Generated: $nowStr', style: _subHeaderStyle());
    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1),
        CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: 1));

    // Count
    _setCell(sheet, 2, 0, 'Workers currently inside: ${rows.length}',
        style: _subHeaderStyle());
    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2),
        CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: 2));

    // Headers
    final headers = ['#', 'Worker Name', 'Card Number', 'Entry Time', 'Time Inside'];
    for (var i = 0; i < headers.length; i++) {
      _setCell(sheet, 3, i, headers[i], style: _subHeaderStyle());
    }

    // Data
    for (var i = 0; i < rows.length; i++) {
      final r = rows[i];
      final style = i.isOdd ? _altRowStyle() : null;
      _setCell(sheet, i + 4, 0, i + 1, style: style);
      _setCell(sheet, i + 4, 1, r['worker_name'], style: style);
      _setCell(sheet, i + 4, 2, r['card_number'], style: style);
      _setCell(sheet, i + 4, 3, r['entry_time'], style: style);
      _setCell(sheet, i + 4, 4, r['duration'], style: style);
    }

    _setColWidth(sheet, 0, 5);
    _setColWidth(sheet, 1, 25);
    _setColWidth(sheet, 2, 18);
    _setColWidth(sheet, 3, 20);
    _setColWidth(sheet, 4, 14);

    final fileName =
        'Muhafiz_Presence_${DateFormat('yyyy-MM-dd_HHmm').format(now)}.xlsx';
    return await _saveFile(excel, fileName);
  }

  // ─── Report 3: Worker Registry ────────────────────────────────────────────

  Future<String> generateWorkerRegistry() async {
    final snap = await _db
        .collection('workers')
        .where('status', whereIn: ['active', 'suspended'])
        .orderBy('worker_name')
        .get();

    final excel = Excel.createExcel();
    final sheet = excel['Worker Registry'];
    excel.delete('Sheet1');

    final now = DateTime.now();
    final nowStr = DateFormat('dd MMMM yyyy').format(now);

    _setCell(sheet, 0, 0, 'MUHAFIZ — WORKER REGISTRY', style: _headerStyle());
    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
        CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: 0));

    _setCell(sheet, 1, 0, 'Generated: $nowStr  |  Total: ${snap.docs.length}',
        style: _subHeaderStyle());
    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1),
        CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: 1));

    final headers = [
      '#', 'Worker Name', 'Card Number', 'CNIC',
      'Worker Type', 'Nature of Service', 'Police Verified', 'Status'
    ];
    for (var i = 0; i < headers.length; i++) {
      _setCell(sheet, 2, i, headers[i], style: _subHeaderStyle());
    }

    for (var i = 0; i < snap.docs.length; i++) {
      final d = snap.docs[i].data();
      final style = i.isOdd ? _altRowStyle() : null;
      _setCell(sheet, i + 3, 0, i + 1, style: style);
      _setCell(sheet, i + 3, 1, d['worker_name'] ?? '—', style: style);
      _setCell(sheet, i + 3, 2, d['card_number'] ?? '—', style: style);
      _setCell(sheet, i + 3, 3, d['cnic'] ?? '—', style: style);
      _setCell(sheet, i + 3, 4, d['worker_type'] ?? '—', style: style);
      _setCell(sheet, i + 3, 5, d['nature_of_service'] ?? '—', style: style);
      _setCell(sheet, i + 3, 6,
          (d['police_verified'] == true) ? 'YES' : 'NO', style: style);
      _setCell(sheet, i + 3, 7, d['status'] ?? '—', style: style);
    }

    _setColWidth(sheet, 0, 5);
    _setColWidth(sheet, 1, 25);
    _setColWidth(sheet, 2, 18);
    _setColWidth(sheet, 3, 18);
    _setColWidth(sheet, 4, 16);
    _setColWidth(sheet, 5, 20);
    _setColWidth(sheet, 6, 16);
    _setColWidth(sheet, 7, 14);

    final fileName =
        'Muhafiz_WorkerRegistry_${DateFormat('yyyy-MM-dd').format(now)}.xlsx';
    return await _saveFile(excel, fileName);
  }
}
