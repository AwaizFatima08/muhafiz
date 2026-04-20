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

  // ─── Date helpers ─────────────────────────────────────────────────────────

  DateTime _startOfDay(DateTime d) =>
      DateTime(d.year, d.month, d.day, 0, 0, 0);

  DateTime _endOfDay(DateTime d) =>
      DateTime(d.year, d.month, d.day, 23, 59, 59);

  String _fmt(DateTime? dt) {
    if (dt == null) return '—';
    return DateFormat('dd/MM/yyyy HH:mm').format(dt);
  }

  // ─── Style helpers ────────────────────────────────────────────────────────

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

  // ─── Parallel worker detail fetch ─────────────────────────────────────────

  /// Fetches name + card_number for a set of worker IDs in parallel.
  /// Returns a map of workerId → {name, cardNumber}.
  Future<Map<String, Map<String, String>>> _fetchWorkerDetails(
      Set<String> workerIds) async {
    final result = <String, Map<String, String>>{};
    await Future.wait(workerIds.map((id) async {
      if (id.isEmpty) return;
      final doc = await _db.collection('workers').doc(id).get();
      if (doc.exists) {
        final d = doc.data()!;
        result[id] = {
          'name':       d['worker_name'] ?? d['name'] ?? 'Unknown',
          'cardNumber': d['card_number'] ?? '—',
          'cnic':       d['cnic'] ?? '—',
        };
      }
    }));
    return result;
  }

  // ─── Save & Share ─────────────────────────────────────────────────────────

  Future<String> _saveFile(Excel excel, String fileName) async {
    final bytes = excel.save();
    if (bytes == null) throw Exception('Failed to encode Excel file');

    Directory dir;
    if (Platform.isAndroid) {
      dir = Directory('/storage/emulated/0/Download');
      if (!await dir.exists()) {
        dir = await getApplicationDocumentsDirectory();
      }
    } else {
      dir = await getApplicationDocumentsDirectory();
    }

    final filePath = '${dir.path}/$fileName';
    await File(filePath).writeAsBytes(bytes);
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
    final end   = Timestamp.fromDate(_endOfDay(date));

    final snap = await _db
        .collection('gate_events')
        .where('processed_at', isGreaterThanOrEqualTo: start)
        .where('processed_at', isLessThanOrEqualTo: end)
        .orderBy('processed_at', descending: false)
        .get();

    // F1 FIX: field is 'worker_id' (snake_case), not 'workerId'.
    final workerIds = snap.docs
        .map((d) => d.data()['worker_id'] as String? ?? '')
        .toSet();
    final workers = await _fetchWorkerDetails(workerIds);

    final excel = Excel.createExcel();
    final sheet = excel['Gate Log'];
    excel.delete('Sheet1');

    final dateStr = DateFormat('dd MMMM yyyy').format(date);

    // Title
    _setCell(sheet, 0, 0, 'MUHAFIZ — DAILY GATE LOG',
        style: _headerStyle());
    sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
        CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: 0));

    // Date
    _setCell(sheet, 1, 0, 'Date: $dateStr', style: _subHeaderStyle());
    sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1),
        CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: 1));

    // Summary
    final entries =
        snap.docs.where((d) => d.data()['event_type'] == 'entry').length;
    final exits =
        snap.docs.where((d) => d.data()['event_type'] == 'exit').length;
    _setCell(sheet, 2, 0,
        'Total: ${snap.docs.length}   |   Entries: $entries   |   Exits: $exits',
        style: _subHeaderStyle());
    sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2),
        CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: 2));

    // Column headers
    final headers = [
      '#', 'Worker Name', 'Card Number', 'Event',
      'Method', 'Processed By', 'Time',
    ];
    for (var i = 0; i < headers.length; i++) {
      _setCell(sheet, 3, i, headers[i], style: _subHeaderStyle());
    }

    // Data rows
    for (var i = 0; i < snap.docs.length; i++) {
      final d         = snap.docs[i].data();
      // F1 FIX: snake_case field names
      final workerId  = d['worker_id'] as String? ?? '';
      final eventType = d['event_type'] as String? ?? '';
      final time      = d['processed_at'] != null
          ? _fmt((d['processed_at'] as Timestamp).toDate())
          : '—';
      final altStyle   = i.isOdd ? _altRowStyle() : null;
      final eventStyle =
          eventType == 'entry' ? _entryStyle() : _exitStyle();

      _setCell(sheet, i + 4, 0, i + 1, style: altStyle);
      _setCell(sheet, i + 4, 1,
          workers[workerId]?['name'] ?? 'Unknown', style: altStyle);
      // F1 FIX: card_number comes from worker doc, not gate_event doc.
      _setCell(sheet, i + 4, 2,
          workers[workerId]?['cardNumber'] ?? '—', style: altStyle);
      _setCell(sheet, i + 4, 3, eventType.toUpperCase(),
          style: eventStyle);
      _setCell(sheet, i + 4, 4, d['method'] ?? '—', style: altStyle);
      _setCell(sheet, i + 4, 5,
          d['processed_by'] ?? '—', style: altStyle);
      _setCell(sheet, i + 4, 6, time, style: altStyle);
    }

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

  // ─── Report 2: Presence Snapshot ──────────────────────────────────────────

  Future<String> generatePresenceSnapshot() async {
    final snap = await _db
        .collection('presence_tracker')
        .where('current_status', isEqualTo: 'inside')
        .get();

    // F2 FIX: presence_tracker docs don't store worker_name/card_number —
    // the doc ID is the workerId. Fetch all worker details in parallel.
    final workerIds = snap.docs.map((d) => d.id).toSet();
    final workers   = await _fetchWorkerDetails(workerIds);

    final rows = <Map<String, dynamic>>[];
    for (final doc in snap.docs) {
      final data      = doc.data();
      final workerId  = doc.id;
      final entryTime = data['last_event_time'] != null
          ? (data['last_event_time'] as Timestamp).toDate()
          : null;
      final duration = entryTime != null
          ? DateTime.now().difference(entryTime)
          : null;
      rows.add({
        'worker_name':      workers[workerId]?['name'] ?? 'Unknown',
        'card_number':      workers[workerId]?['cardNumber'] ?? '—',
        'entry_time':       _fmt(entryTime),
        'duration':         duration != null
            ? '${duration.inHours}h ${duration.inMinutes % 60}m'
            : '—',
        'duration_minutes': duration?.inMinutes ?? 0,
      });
    }

    // Sort longest inside first
    rows.sort((a, b) => (b['duration_minutes'] as int)
        .compareTo(a['duration_minutes'] as int));

    final excel = Excel.createExcel();
    final sheet = excel['Presence Snapshot'];
    excel.delete('Sheet1');

    final now    = DateTime.now();
    final nowStr = DateFormat('dd MMMM yyyy HH:mm').format(now);

    _setCell(sheet, 0, 0, 'MUHAFIZ — PRESENCE SNAPSHOT',
        style: _headerStyle());
    sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
        CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: 0));

    _setCell(sheet, 1, 0, 'Generated: $nowStr',
        style: _subHeaderStyle());
    sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1),
        CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: 1));

    _setCell(sheet, 2, 0,
        'Workers currently inside: ${rows.length}',
        style: _subHeaderStyle());
    sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2),
        CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: 2));

    final headers = [
      '#', 'Worker Name', 'Card Number', 'Entry Time', 'Time Inside',
    ];
    for (var i = 0; i < headers.length; i++) {
      _setCell(sheet, 3, i, headers[i], style: _subHeaderStyle());
    }

    for (var i = 0; i < rows.length; i++) {
      final r     = rows[i];
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

    final now    = DateTime.now();
    final nowStr = DateFormat('dd MMMM yyyy').format(now);

    _setCell(sheet, 0, 0, 'MUHAFIZ — WORKER REGISTRY',
        style: _headerStyle());
    sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
        CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: 0));

    _setCell(sheet, 1, 0,
        'Generated: $nowStr  |  Total: ${snap.docs.length}',
        style: _subHeaderStyle());
    sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1),
        CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: 1));

    final headers = [
      '#', 'Worker Name', 'Card Number', 'CNIC',
      'Worker Type', 'Nature of Service', 'Police Verified', 'Status',
    ];
    for (var i = 0; i < headers.length; i++) {
      _setCell(sheet, 2, i, headers[i], style: _subHeaderStyle());
    }

    for (var i = 0; i < snap.docs.length; i++) {
      final d     = snap.docs[i].data();
      final style = i.isOdd ? _altRowStyle() : null;
      _setCell(sheet, i + 3, 0, i + 1, style: style);
      _setCell(sheet, i + 3, 1, d['worker_name'] ?? '—', style: style);
      _setCell(sheet, i + 3, 2, d['card_number'] ?? '—', style: style);
      _setCell(sheet, i + 3, 3, d['cnic'] ?? '—', style: style);
      _setCell(sheet, i + 3, 4, d['worker_type'] ?? '—', style: style);
      _setCell(sheet, i + 3, 5,
          d['nature_of_service'] ?? '—', style: style);
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

  // ─── Report 4: Guest Visit Log ────────────────────────────────────────────

  Future<String> generateGuestVisitLog(DateTime date) async {
    final start = _startOfDay(date);
    final end   = start.add(const Duration(days: 1));

    final snap = await _db
        .collection('guest_visits')
        .where('entry_time',
            isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('entry_time', isLessThan: Timestamp.fromDate(end))
        .orderBy('entry_time', descending: false)
        .get();

    final excel = Excel.createExcel();
    final sheet = excel['Guest Visits'];
    excel.delete('Sheet1');
    final fmt = DateFormat('HH:mm');

    _setCell(sheet, 0, 0, 'MUHAFIZ — GUEST VISIT LOG',
        style: _headerStyle());
    sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
        CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: 0));

    _setCell(sheet, 1, 0,
        'Date: ${DateFormat('dd MMMM yyyy').format(date)}  |  Total: ${snap.docs.length}',
        style: _subHeaderStyle());
    sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1),
        CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: 1));

    final headers = [
      '#', 'Visitor Name', 'CNIC', 'House', 'Resident',
      'Purpose', 'Vehicle', 'Entry', 'Exit', 'Status',
    ];
    for (var i = 0; i < headers.length; i++) {
      _setCell(sheet, 2, i, headers[i], style: _subHeaderStyle());
    }

    for (var i = 0; i < snap.docs.length; i++) {
      final d       = snap.docs[i].data();
      final style   = i.isOdd ? _altRowStyle() : null;
      final entryTs = d['entry_time'] as Timestamp?;
      final exitTs  = d['exit_time']  as Timestamp?;
      _setCell(sheet, i + 3, 0, i + 1, style: style);
      _setCell(sheet, i + 3, 1, d['visitor_name'] ?? '', style: style);
      _setCell(sheet, i + 3, 2,
          d['visitor_cnic']?.toString() ?? '', style: style);
      _setCell(sheet, i + 3, 3, d['house_number'] ?? '', style: style);
      _setCell(sheet, i + 3, 4, d['resident_name'] ?? '', style: style);
      _setCell(sheet, i + 3, 5, d['purpose'] ?? '', style: style);
      _setCell(sheet, i + 3, 6,
          d['vehicle_registration_number'] ?? '', style: style);
      _setCell(sheet, i + 3, 7,
          entryTs != null ? fmt.format(entryTs.toDate()) : '',
          style: style);
      _setCell(sheet, i + 3, 8,
          exitTs != null ? fmt.format(exitTs.toDate()) : '—',
          style: style);
      _setCell(sheet, i + 3, 9, d['status'] ?? '', style: style);
    }

    _setColWidth(sheet, 0, 5);
    _setColWidth(sheet, 1, 22);
    _setColWidth(sheet, 2, 16);
    _setColWidth(sheet, 3, 10);
    _setColWidth(sheet, 4, 20);
    _setColWidth(sheet, 5, 16);
    _setColWidth(sheet, 6, 14);
    _setColWidth(sheet, 7, 10);
    _setColWidth(sheet, 8, 10);
    _setColWidth(sheet, 9, 12);

    final fileName =
        'Muhafiz_GuestVisits_${DateFormat('yyyy-MM-dd').format(date)}.xlsx';
    return await _saveFile(excel, fileName);
  }

  // ─── Report 5: Vehicle Log ────────────────────────────────────────────────

  Future<String> generateVehicleLog(DateTime date) async {
    final start = _startOfDay(date);
    final end   = start.add(const Duration(days: 1));

    final snap = await _db
        .collection('vehicle_events')
        .where('processed_at',
            isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('processed_at', isLessThan: Timestamp.fromDate(end))
        .orderBy('processed_at', descending: false)
        .get();

    // Fetch resident names for the vehicle events
    final residentIds = snap.docs
        .map((d) => d.data()['resident_id'] as String? ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();
    final residentNames = <String, String>{};
    await Future.wait(residentIds.map((id) async {
      final doc = await _db.collection('residents').doc(id).get();
      if (doc.exists) {
        residentNames[id] = doc.data()?['name'] as String? ?? id;
      }
    }));

    final excel = Excel.createExcel();
    final sheet = excel['Vehicle Events'];
    excel.delete('Sheet1');
    final fmt = DateFormat('HH:mm');

    _setCell(sheet, 0, 0, 'MUHAFIZ — VEHICLE LOG',
        style: _headerStyle());
    sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
        CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: 0));

    _setCell(sheet, 1, 0,
        'Date: ${DateFormat('dd MMMM yyyy').format(date)}  |  Total: ${snap.docs.length}',
        style: _subHeaderStyle());
    sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1),
        CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: 1));

    final headers = [
      '#', 'Plate Number', 'Event', 'Method', 'Resident', 'Time',
    ];
    for (var i = 0; i < headers.length; i++) {
      _setCell(sheet, 2, i, headers[i], style: _subHeaderStyle());
    }

    for (var i = 0; i < snap.docs.length; i++) {
      final d          = snap.docs[i].data();
      final style      = i.isOdd ? _altRowStyle() : null;
      final ts         = d['processed_at'] as Timestamp?;
      final residentId = d['resident_id'] as String? ?? '';
      _setCell(sheet, i + 3, 0, i + 1, style: style);
      _setCell(sheet, i + 3, 1,
          d['vehicle_registration_number'] ?? '', style: style);
      _setCell(sheet, i + 3, 2, d['event_type'] ?? '', style: style);
      _setCell(sheet, i + 3, 3, d['method'] ?? '', style: style);
      // F5 FIX: show resident name instead of raw resident_id
      _setCell(sheet, i + 3, 4,
          residentNames[residentId] ?? residentId, style: style);
      _setCell(sheet, i + 3, 5,
          ts != null ? fmt.format(ts.toDate()) : '', style: style);
    }

    _setColWidth(sheet, 0, 5);
    _setColWidth(sheet, 1, 18);
    _setColWidth(sheet, 2, 10);
    _setColWidth(sheet, 3, 12);
    _setColWidth(sheet, 4, 22);
    _setColWidth(sheet, 5, 10);

    final fileName =
        'Muhafiz_VehicleLog_${DateFormat('yyyy-MM-dd').format(date)}.xlsx';
    return await _saveFile(excel, fileName);
  }

  // ─── Resident Registry ────────────────────────────────────────────────────

  Future<String> generateResidentRegistry() async {
    final snap = await _db
        .collection('residents')
        .where('is_active', isEqualTo: true)
        .orderBy('house_number')
        .get();

    final excel = Excel.createExcel();
    final sheet = excel['Residents'];
    excel.delete('Sheet1');

    final now    = DateTime.now();
    final nowStr = DateFormat('dd MMMM yyyy').format(now);

    _setCell(sheet, 0, 0, 'MUHAFIZ — RESIDENT REGISTRY',
        style: _headerStyle());
    sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
        CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: 0));

    _setCell(sheet, 1, 0,
        'Generated: $nowStr  |  Total: ${snap.docs.length}',
        style: _subHeaderStyle());
    sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1),
        CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: 1));

    final headers = [
      '#', 'Name', 'House', 'Block',
      'Phone', 'Employee No', 'Organisation', 'Status',
    ];
    for (var i = 0; i < headers.length; i++) {
      _setCell(sheet, 2, i, headers[i], style: _subHeaderStyle());
    }

    for (var i = 0; i < snap.docs.length; i++) {
      final d     = snap.docs[i].data();
      final style = i.isOdd ? _altRowStyle() : null;
      _setCell(sheet, i + 3, 0, i + 1, style: style);
      _setCell(sheet, i + 3, 1, d['name'] ?? '', style: style);
      _setCell(sheet, i + 3, 2, d['house_number'] ?? '', style: style);
      _setCell(sheet, i + 3, 3, d['block'] ?? '', style: style);
      _setCell(sheet, i + 3, 4, d['phone_mobile'] ?? '', style: style);
      _setCell(sheet, i + 3, 5,
          d['employee_number'] ?? d['resident_number'] ?? '',
          style: style);
      _setCell(sheet, i + 3, 6,
          d['organisation_id'] ?? '', style: style);
      _setCell(sheet, i + 3, 7, d['status'] ?? '', style: style);
    }

    _setColWidth(sheet, 0, 5);
    _setColWidth(sheet, 1, 22);
    _setColWidth(sheet, 2, 10);
    _setColWidth(sheet, 3, 10);
    _setColWidth(sheet, 4, 16);
    _setColWidth(sheet, 5, 16);
    _setColWidth(sheet, 6, 20);
    _setColWidth(sheet, 7, 14);

    final fileName =
        'Muhafiz_ResidentRegistry_${DateFormat('yyyy-MM-dd').format(now)}.xlsx';
    return await _saveFile(excel, fileName);
  }

  // ─── Card Expiry Alerts ───────────────────────────────────────────────────

  Future<String> generateCardExpiryAlerts() async {
    final cutoff = DateTime.now().add(const Duration(days: 30));

    final snap = await _db
        .collection('workers')
        .where('status', whereIn: ['active', 'pendingApproval'])
        .get();

    final expiring = snap.docs.where((doc) {
      final d      = doc.data();
      final expiry = d['card_expiry_date'];
      if (expiry == null) return false;
      final dt = expiry is Timestamp
          ? expiry.toDate()
          : DateTime.tryParse(expiry.toString());
      return dt != null && dt.isBefore(cutoff);
    }).toList()
      ..sort((a, b) {
        // Sort by expiry date ascending (soonest first)
        DateTime? dtA, dtB;
        final ea = a.data()['card_expiry_date'];
        final eb = b.data()['card_expiry_date'];
        dtA = ea is Timestamp
            ? ea.toDate()
            : DateTime.tryParse(ea?.toString() ?? '');
        dtB = eb is Timestamp
            ? eb.toDate()
            : DateTime.tryParse(eb?.toString() ?? '');
        return (dtA ?? DateTime(9999))
            .compareTo(dtB ?? DateTime(9999));
      });

    final excel = Excel.createExcel();
    final sheet = excel['Card Expiry'];
    excel.delete('Sheet1');
    final fmt = DateFormat('dd/MM/yyyy');

    _setCell(sheet, 0, 0, 'MUHAFIZ — CARD EXPIRY ALERTS',
        style: _headerStyle());
    sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
        CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: 0));

    _setCell(sheet, 1, 0,
        'Expiring within 30 days  |  Total: ${expiring.length}',
        style: _subHeaderStyle());
    sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1),
        CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: 1));

    final headers = [
      '#', 'Worker Name', 'Card Number', 'CNIC', 'Expiry Date', 'Days Left',
    ];
    for (var i = 0; i < headers.length; i++) {
      _setCell(sheet, 2, i, headers[i], style: _subHeaderStyle());
    }

    for (var i = 0; i < expiring.length; i++) {
      final d      = expiring[i].data();
      final style  = i.isOdd ? _altRowStyle() : null;
      final expiry = d['card_expiry_date'];
      final dt     = expiry is Timestamp
          ? expiry.toDate()
          : DateTime.tryParse(expiry?.toString() ?? '');
      final daysLeft = dt != null
          ? dt.difference(DateTime.now()).inDays
          : 0;
      _setCell(sheet, i + 3, 0, i + 1, style: style);
      _setCell(sheet, i + 3, 1, d['worker_name'] ?? '', style: style);
      _setCell(sheet, i + 3, 2, d['card_number'] ?? '', style: style);
      _setCell(sheet, i + 3, 3, d['cnic'] ?? '', style: style);
      _setCell(sheet, i + 3, 4,
          dt != null ? fmt.format(dt) : '—', style: style);
      _setCell(sheet, i + 3, 5, daysLeft, style: style);
    }

    _setColWidth(sheet, 0, 5);
    _setColWidth(sheet, 1, 25);
    _setColWidth(sheet, 2, 18);
    _setColWidth(sheet, 3, 18);
    _setColWidth(sheet, 4, 16);
    _setColWidth(sheet, 5, 12);

    final now      = DateTime.now();
    final fileName =
        'Muhafiz_CardExpiry_${DateFormat('yyyy-MM-dd').format(now)}.xlsx';
    return await _saveFile(excel, fileName);
  }

  // ─── Emergency Muster ─────────────────────────────────────────────────────

  Future<String> generateEmergencyMuster() async {
    final now = DateTime.now();
    final fmt = DateFormat('HH:mm');

    // Workers inside
    final presenceSnap = await _db
        .collection('presence_tracker')
        .where('current_status', isEqualTo: 'inside')
        .get();

    // Guests inside
    final guestSnap = await _db
        .collection('guest_visits')
        .where('status', isEqualTo: 'inside')
        .get();

    // F4 FIX: fetch worker details — presence docs don't store name/card.
    final workerIds =
        presenceSnap.docs.map((d) => d.id).toSet();
    final workers = await _fetchWorkerDetails(workerIds);

    final excel = Excel.createExcel();

    // Summary sheet first
    final ss = excel['Summary'];
    _setCell(ss, 0, 0, 'MUHAFIZ — EMERGENCY MUSTER',
        style: _headerStyle());
    _sheetMergeSafe(ss, 0, 0, 0, 3);
    _setCell(ss, 1, 0,
        'Generated: ${DateFormat('dd/MM/yyyy HH:mm').format(now)}',
        style: _subHeaderStyle());
    _sheetMergeSafe(ss, 1, 0, 1, 3);
    _setCell(ss, 2, 0,
        'Workers Inside: ${presenceSnap.docs.length}',
        style: _subHeaderStyle());
    _setCell(ss, 3, 0,
        'Guests Inside: ${guestSnap.docs.length}',
        style: _subHeaderStyle());

    // Workers sheet
    final ws      = excel['Workers Inside'];
    final wHeaders = ['#', 'Worker Name', 'Card Number', 'Entry Time'];
    for (var i = 0; i < wHeaders.length; i++) {
      _setCell(ws, 0, i, wHeaders[i], style: _subHeaderStyle());
    }
    for (var i = 0; i < presenceSnap.docs.length; i++) {
      final d     = presenceSnap.docs[i].data();
      final wId   = presenceSnap.docs[i].id;
      final style = i.isOdd ? _altRowStyle() : null;
      final ts    = d['last_event_time'] as Timestamp?;
      _setCell(ws, i + 1, 0, i + 1, style: style);
      // F4 FIX: use fetched worker details
      _setCell(ws, i + 1, 1,
          workers[wId]?['name'] ?? 'Unknown', style: style);
      _setCell(ws, i + 1, 2,
          workers[wId]?['cardNumber'] ?? '—', style: style);
      _setCell(ws, i + 1, 3,
          ts != null ? fmt.format(ts.toDate()) : '', style: style);
    }

    // Guests sheet
    final gs      = excel['Guests Inside'];
    final gHeaders = [
      '#', 'Visitor', 'CNIC', 'House', 'Purpose', 'Entry', 'Expires',
    ];
    for (var i = 0; i < gHeaders.length; i++) {
      _setCell(gs, 0, i, gHeaders[i], style: _subHeaderStyle());
    }
    for (var i = 0; i < guestSnap.docs.length; i++) {
      final d       = guestSnap.docs[i].data();
      final style   = i.isOdd ? _altRowStyle() : null;
      final entryTs = d['entry_time']  as Timestamp?;
      // F4 FIX: typo 'espires_at' corrected to 'expires_at'
      final expiryTs = d['expires_at'] as Timestamp?;
      _setCell(gs, i + 1, 0, i + 1, style: style);
      _setCell(gs, i + 1, 1, d['visitor_name'] ?? '', style: style);
      _setCell(gs, i + 1, 2,
          d['visitor_cnic']?.toString() ?? '', style: style);
      _setCell(gs, i + 1, 3, d['house_number'] ?? '', style: style);
      _setCell(gs, i + 1, 4, d['purpose'] ?? '', style: style);
      _setCell(gs, i + 1, 5,
          entryTs != null ? fmt.format(entryTs.toDate()) : '',
          style: style);
      _setCell(gs, i + 1, 6,
          expiryTs != null ? fmt.format(expiryTs.toDate()) : '—',
          style: style);
    }

    excel.delete('Sheet1');

    final fileName =
        'Muhafiz_Muster_${DateFormat('yyyyMMdd_HHmm').format(now)}.xlsx';
    return await _saveFile(excel, fileName);
  }

  // Helper for merge without crashing on single-cell ranges
  void _sheetMergeSafe(
      Sheet sheet, int r1, int c1, int r2, int c2) {
    if (r1 == r2 && c1 == c2) return;
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: c1, rowIndex: r1),
      CellIndex.indexByColumnRow(columnIndex: c2, rowIndex: r2),
    );
  }
}
