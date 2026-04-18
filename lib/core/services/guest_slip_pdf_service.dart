import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/material.dart' as material;
import '../models/guest_visit_model.dart';
import '../models/site_settings_model.dart';

class GuestSlipPdfService {
  // 80mm thermal printer — usable width ~72mm at 203dpi ≈ 576 points
  static const double _pageWidth  = 72 * PdfPageFormat.mm;
  static const double _pageHeight = 140 * PdfPageFormat.mm;

  /// Generates the bilingual guest slip PDF and returns bytes.
  static Future<Uint8List> generate({
    required GuestVisitModel visit,
    required SiteSettings settings,
    required String clerkName,
  }) async {
    final pdf  = pw.Document();
    final font = await PdfGoogleFonts.notoSansRegular();
    final fontBold = await PdfGoogleFonts.notoSansBold();

    // Load Noto Nastaliq for Urdu
    pw.Font? urduFont;
    try {
      final fontData = await rootBundle.load(
          'assets/fonts/NotoNastaliqUrdu-Regular.ttf');
      urduFont = pw.Font.ttf(fontData);
    } catch (_) {
      urduFont = font; // fallback
    }

    // QR code image bytes
    final qrBytes = await _generateQrBytes(visit.slipQrValue);

    // Format times
    final fmt      = DateFormat('dd/MM/yyyy HH:mm');
    final entryStr = fmt.format(visit.entryTime);
    final expiryStr = fmt.format(visit.expiresAt);

    // Warnings
    final enWarnings = settings.guestSlipWarnings?.english ?? {};
    final urWarnings = settings.guestSlipWarnings?.urdu ?? {};

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(_pageWidth, _pageHeight,
            marginAll: 4 * PdfPageFormat.mm),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────
            pw.Center(
              child: pw.Column(children: [
                pw.Text(settings.siteName,
                    style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 11,
                        color: PdfColors.black)),
                pw.SizedBox(height: 2),
                pw.Text('VISITOR ENTRY SLIP',
                    style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 8,
                        letterSpacing: 1.5,
                        color: PdfColors.grey700)),
              ]),
            ),
            pw.Divider(thickness: 0.5, color: PdfColors.black),

            // ── Visitor details ──────────────────────────────────────────
            _row(font, fontBold, 'Visitor', visit.visitorName),
            _row(font, fontBold, 'CNIC', visit.visitorCnic),
            _row(font, fontBold, 'Visiting',
                '${visit.houseNumber} — ${visit.residentName}'),
            _row(font, fontBold, 'Purpose', visit.purpose),
            if (visit.vehicleRegistrationNumber != null &&
                visit.vehicleRegistrationNumber!.isNotEmpty)
              _row(font, fontBold, 'Vehicle',
                  visit.vehicleRegistrationNumber!),
            pw.SizedBox(height: 3),
            _row(font, fontBold, 'Entry', entryStr),
            _row(font, fontBold, 'Valid Until', expiryStr,
                valueColor: PdfColors.red700),
            pw.SizedBox(height: 4),

            // ── QR code + slip ID ────────────────────────────────────────
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                if (qrBytes != null)
                  pw.Image(pw.MemoryImage(qrBytes),
                      width: 48, height: 48)
                else
                  pw.SizedBox(width: 48, height: 48),
                pw.SizedBox(width: 6),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Slip ID',
                          style: pw.TextStyle(
                              font: font,
                              fontSize: 7,
                              color: PdfColors.grey600)),
                      pw.Text(visit.id.substring(0, 12).toUpperCase(),
                          style: pw.TextStyle(
                              font: fontBold,
                              fontSize: 7)),
                      pw.SizedBox(height: 4),
                      pw.Text('Processed by: $clerkName',
                          style: pw.TextStyle(
                              font: font,
                              fontSize: 7,
                              color: PdfColors.grey600)),
                    ],
                  ),
                ),
              ],
            ),
            pw.Divider(thickness: 0.5, color: PdfColors.black),

            // ── English warnings ─────────────────────────────────────────
            if (enWarnings.isNotEmpty) ...[
              pw.Text('Instructions',
                  style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 7,
                      color: PdfColors.grey700)),
              pw.SizedBox(height: 2),
              ...enWarnings.entries.toList().asMap().entries.map((entry) {
                final i = entry.key + 1;
                final text = entry.value.value;
                return pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 2),
                  child: pw.Text('$i. $text',
                      style: pw.TextStyle(font: font, fontSize: 6.5)),
                );
              }),
              pw.SizedBox(height: 3),
            ],

            // ── Urdu warnings ────────────────────────────────────────────
            if (urWarnings.isNotEmpty && urduFont != null) ...[
              pw.Divider(
                  thickness: 0.3, color: PdfColors.grey400),
              pw.SizedBox(height: 2),
              pw.Text('ہدایات',
                  textDirection: pw.TextDirection.rtl,
                  style: pw.TextStyle(
                      font: urduFont,
                      fontSize: 8,
                      color: PdfColors.grey700)),
              pw.SizedBox(height: 2),
              ...urWarnings.entries.toList().asMap().entries.map((entry) {
                final text = entry.value.value;
                return pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 2),
                  child: pw.Text(text,
                      textDirection: pw.TextDirection.rtl,
                      style: pw.TextStyle(
                          font: urduFont, fontSize: 7)),
                );
              }),
            ],

            // ── Footer ───────────────────────────────────────────────────
            pw.Spacer(),
            pw.Divider(thickness: 0.3, color: PdfColors.grey400),
            pw.Center(
              child: pw.Text(settings.siteName + ' — Security Office',
                  style: pw.TextStyle(
                      font: font,
                      fontSize: 6,
                      color: PdfColors.grey500)),
            ),
          ],
        ),
      ),
    );

    return pdf.save();
  }

  static pw.Widget _row(
    pw.Font font,
    pw.Font fontBold,
    String label,
    String value, {
    PdfColor valueColor = PdfColors.black,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 42,
            child: pw.Text(label,
                style: pw.TextStyle(
                    font: font,
                    fontSize: 7,
                    color: PdfColors.grey700)),
          ),
          pw.Text(': ',
              style: pw.TextStyle(font: font, fontSize: 7,
                  color: PdfColors.grey600)),
          pw.Expanded(
            child: pw.Text(value,
                style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 7,
                    color: valueColor)),
          ),
        ],
      ),
    );
  }

  static Future<Uint8List?> _generateQrBytes(String data) async {
    try {
      final painter = QrPainter(
        data: data,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.M,
        color: const material.Color(0xFF000000),
        emptyColor: const material.Color(0xFFFFFFFF),
      );
      final image = await painter.toImageData(200);
      return image?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  /// Print to Bluetooth thermal printer via raster method.
  static Future<void> printSlip(Uint8List pdfBytes) async {
    await Printing.layoutPdf(
      onLayout: (_) async => pdfBytes,
      format: PdfPageFormat(_pageWidth, _pageHeight),
    );
  }

  /// Share/save PDF (fallback if no printer).
  static Future<void> sharePdf(Uint8List pdfBytes, String visitId) async {
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: 'guest_slip_$visitId.pdf',
    );
  }
}
