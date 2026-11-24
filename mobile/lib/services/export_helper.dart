import 'dart:io';
import 'dart:typed_data';
import 'package:excel/excel.dart' as xl;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/settings_provider.dart';
import '../widgets/app_toast.dart';

class ExportHelper {
  static Future<Directory> resolveDownloadsDirectory() async {
    if (Platform.isAndroid) {
      final downloadDir = Directory('/storage/emulated/0/Download');
      if (await downloadDir.exists()) return downloadDir;
      final extDir = await getExternalStorageDirectory();
      if (extDir != null) return extDir;
    }
    return getApplicationDocumentsDirectory();
  }

  static Future<File?> saveExcelAndShare(
    BuildContext context, {
    required xl.Excel excel,
    required String fileName,
    required String shareText,
    String toastPrefix = 'Fichier Excel généré : ',
    bool showFullPath = false,
  }) async {
    final fileBytes = excel.save();
    if (fileBytes == null) return null;
    final dir = await resolveDownloadsDirectory();
    final file = File(p.join(dir.path, fileName));
    await file.writeAsBytes(fileBytes);
    if (context.mounted) {
      final label = showFullPath ? file.path : file.path.split('/').last;
      AppToast.showSuccess(context, '$toastPrefix$label');
    }
    await Share.shareXFiles([XFile(file.path)], text: shareText);
    return file;
  }

  static Future<void> shareBytesAsFile(
    BuildContext context, {
    required List<int> bytes,
    required String fileName,
    required String shareText,
    String errorPrefix = 'Erreur lors du partage : ',
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File(p.join(tempDir.path, fileName));
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)], text: shareText);
    } catch (e) {
      if (context.mounted) {
        AppToast.showError(context, '$errorPrefix$e');
      }
    }
  }

  static Future<void> downloadBytes(
    BuildContext context, {
    required List<int> bytes,
    required String fileName,
    String successPrefix = 'Fichier téléchargé dans : ',
    bool showBasenameOnly = false,
    String errorPrefix = 'Erreur lors du téléchargement : ',
  }) async {
    try {
      final targetDir = await resolveDownloadsDirectory();
      final file = File(p.join(targetDir.path, fileName));
      await file.writeAsBytes(bytes);
      if (context.mounted) {
        final label = showBasenameOnly ? file.path.split('/').last : file.path;
        AppToast.showSuccess(context, '$successPrefix$label');
      }
    } catch (e) {
      if (context.mounted) {
        AppToast.showError(context, '$errorPrefix$e');
      }
    }
  }

  static pw.Widget buildPdfStoreHeader(
    StoreSettings settings, {
    required String title,
    required String subtitle,
    PdfColor titleColor = PdfColors.blue900,
  }) {
    final editedAt = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  settings.name.toUpperCase(),
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16),
                ),
                if (settings.phone.isNotEmpty)
                  pw.Text('Tél: ${settings.phone}', style: const pw.TextStyle(fontSize: 10)),
                if (settings.address.isNotEmpty)
                  pw.Text(settings.address, style: const pw.TextStyle(fontSize: 10)),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  title,
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 12,
                    color: titleColor,
                  ),
                ),
                pw.Text(subtitle, style: const pw.TextStyle(fontSize: 10)),
                pw.Text(
                  'Édité le : $editedAt',
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 16),
        pw.Divider(thickness: 1),
        pw.SizedBox(height: 12),
      ],
    );
  }

  static pw.Widget buildPdfMetricCard(String label, String value, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey100,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
          border: pw.Border.all(color: color, width: 1),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
            pw.SizedBox(height: 4),
            pw.Text(value, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  static Future<void> layoutPdf(pw.Document pdf, String name) async {
    await Printing.layoutPdf(onLayout: (PdfPageFormat _) async => pdf.save(), name: name);
  }

  static Future<Uint8List> buildPaymentReceiptPdf({
    required String title,
    required String receiptNumber,
    required String partyLabel,
    required String partyName,
    String? partyPhone,
    String? partyContact,
    required double amountPaid,
    required String paymentMethod,
    double? previousBalance,
    required double remainingBalance,
    required String remainingLabel,
    required String footerText,
    required StoreSettings storeSettings,
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR');
    final moneyFmt = NumberFormat.currency(locale: 'fr_FR', symbol: storeSettings.currency, decimalDigits: 0);

    pw.Widget kvRow(String k, String v, {bool bold = false, double fontSize = 8}) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 4),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(k, style: pw.TextStyle(fontSize: fontSize, fontWeight: bold ? pw.FontWeight.bold : null)),
              pw.Text(v, style: pw.TextStyle(fontSize: fontSize, fontWeight: bold ? pw.FontWeight.bold : null)),
            ],
          ),
        );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.all(12),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(storeSettings.name.toUpperCase(), style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  if (storeSettings.address.isNotEmpty) pw.Text(storeSettings.address, style: const pw.TextStyle(fontSize: 8)),
                  if (storeSettings.phone.isNotEmpty) pw.Text('Tél : ${storeSettings.phone}', style: const pw.TextStyle(fontSize: 8)),
                  if (storeSettings.email.isNotEmpty) pw.Text(storeSettings.email, style: const pw.TextStyle(fontSize: 8)),
                ],
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Divider(thickness: 0.5),
            pw.Center(child: pw.Text(title, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center)),
            pw.SizedBox(height: 6),
            kvRow('N° : $receiptNumber', dateFmt.format(now)),
            pw.Text('$partyLabel : $partyName', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
            if (partyPhone != null && partyPhone.isNotEmpty) pw.Text('Tél : $partyPhone', style: const pw.TextStyle(fontSize: 8)),
            if (partyContact != null && partyContact.isNotEmpty) pw.Text('Contact : $partyContact', style: const pw.TextStyle(fontSize: 8)),
            pw.SizedBox(height: 6),
            pw.Divider(thickness: 0.5),
            pw.SizedBox(height: 6),
            kvRow('Montant Versé :', moneyFmt.format(amountPaid), bold: true, fontSize: 9),
            kvRow('Mode de Règlement :', paymentMethod),
            if (previousBalance != null) kvRow('Ancienne Dette :', moneyFmt.format(previousBalance)),
            kvRow(remainingLabel, moneyFmt.format(remainingBalance), bold: true),
            pw.SizedBox(height: 10),
            pw.Divider(thickness: 0.5),
            pw.Center(child: pw.Text(footerText, style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic))),
          ],
        ),
      ),
    );
    return pdf.save();
  }
}
