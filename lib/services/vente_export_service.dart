import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/vente.dart';
import '../providers/settings_provider.dart';
import '../widgets/app_toast.dart';

class VenteExportService {
  static Future<void> exportVentesExcel(
    BuildContext context,
    List<Vente> ventes,
    String periodLabel,
  ) async {
    try {
      final excel = Excel.createExcel();
      final Sheet sheet = excel['Ventes'];
      excel.setDefaultSheet('Ventes');

      // Title & Header
      sheet.appendRow([TextCellValue('REGISTRE DES VENTES - $periodLabel')]);
      sheet.appendRow([TextCellValue('Généré le : ${DateFormat('dd/MM/yyyy HH:mm', 'fr_FR').format(DateTime.now())}')]);
      sheet.appendRow([]); // Empty row

      // Table Header
      sheet.appendRow([
        TextCellValue('Ticket N°'),
        TextCellValue('Date & Heure'),
        TextCellValue('Client'),
        TextCellValue('Mode de Paiement'),
        TextCellValue('Total Net (FCFA)'),
        TextCellValue('Montant Versé (FCFA)'),
        TextCellValue('Reste Dû (FCFA)'),
        TextCellValue('Nombre d\'articles'),
      ]);

      double totalCA = 0;
      double totalPaye = 0;
      double totalCredit = 0;

      for (final v in ventes) {
        totalCA += v.totalAmount;
        totalPaye += v.paidAmount;
        totalCredit += v.remainingAmount;

        sheet.appendRow([
          TextCellValue(v.ticketNumber.isNotEmpty ? v.ticketNumber : 'VNT-${v.id}'),
          TextCellValue(DateFormat('dd/MM/yyyy HH:mm', 'fr_FR').format(v.date)),
          TextCellValue(v.clientName ?? 'Occasionnel'),
          TextCellValue(v.paymentMethod),
          DoubleCellValue(v.totalAmount),
          DoubleCellValue(v.paidAmount),
          DoubleCellValue(v.remainingAmount),
          IntCellValue(v.items.length),
        ]);
      }

      sheet.appendRow([]); // Empty row
      sheet.appendRow([
        TextCellValue('RÉCAPITULATIF'),
        TextCellValue(''),
        TextCellValue(''),
        TextCellValue('TOTALS :'),
        DoubleCellValue(totalCA),
        DoubleCellValue(totalPaye),
        DoubleCellValue(totalCredit),
        IntCellValue(ventes.length),
      ]);

      final fileBytes = excel.save();
      if (fileBytes == null) throw Exception('Impossible d\'engendrer le fichier Excel');

      Directory targetDir;
      if (Platform.isAndroid) {
        final downloadDir = Directory('/storage/emulated/0/Download');
        if (await downloadDir.exists()) {
          targetDir = downloadDir;
        } else {
          targetDir = await getApplicationDocumentsDirectory();
        }
      } else {
        targetDir = await getApplicationDocumentsDirectory();
      }

      final fileName = 'Registre_Ventes_${periodLabel.replaceAll(' ', '_')}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';
      final filePath = p.join(targetDir.path, fileName);
      final file = File(filePath);
      await file.writeAsBytes(fileBytes);

      if (context.mounted) {
        AppToast.showSuccess(context, 'Fichier Excel enregistré dans : ${file.path}');
      }

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Registre des Ventes ($periodLabel)',
      );
    } catch (e) {
      if (context.mounted) {
        AppToast.showError(context, 'Erreur d\'exportation Excel : $e');
      }
    }
  }

  static Future<void> exportVentesPdfReport(
    BuildContext context,
    List<Vente> ventes,
    String periodLabel,
    StoreSettings storeSettings,
  ) async {
    try {
      final pdf = pw.Document();
      final dateFormat = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR');
      final formatter = NumberFormat.currency(locale: 'fr_FR', symbol: storeSettings.currency, decimalDigits: 0);

      double totalCA = 0;
      double totalEncaisse = 0;
      double totalCredit = 0;

      for (final v in ventes) {
        totalCA += v.totalAmount;
        totalEncaisse += v.paidAmount;
        totalCredit += v.remainingAmount;
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          build: (pw.Context ctx) {
            return [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(storeSettings.name.toUpperCase(), style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                      if (storeSettings.address.isNotEmpty) pw.Text(storeSettings.address, style: const pw.TextStyle(fontSize: 10)),
                      if (storeSettings.phone.isNotEmpty) pw.Text('Tél: ${storeSettings.phone}', style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('RAPPORT DE VENTES', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Période : $periodLabel', style: const pw.TextStyle(fontSize: 10)),
                      pw.Text('Date : ${dateFormat.format(DateTime.now())}', style: const pw.TextStyle(fontSize: 9)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 12),

              // Metrics Cards
              pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey300),
                        borderRadius: pw.BorderRadius.circular(8),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Total Ventes', style: const pw.TextStyle(fontSize: 9)),
                          pw.SizedBox(height: 2),
                          pw.Text('${ventes.length}', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 8),
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey300),
                        borderRadius: pw.BorderRadius.circular(8),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Chiffre d\'Affaires', style: const pw.TextStyle(fontSize: 9)),
                          pw.SizedBox(height: 2),
                          pw.Text(formatter.format(totalCA), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 8),
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey300),
                        borderRadius: pw.BorderRadius.circular(8),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Encaissé', style: const pw.TextStyle(fontSize: 9)),
                          pw.SizedBox(height: 2),
                          pw.Text(formatter.format(totalEncaisse), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 8),
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey300),
                        borderRadius: pw.BorderRadius.circular(8),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Crédits en cours', style: const pw.TextStyle(fontSize: 9)),
                          pw.SizedBox(height: 2),
                          pw.Text(formatter.format(totalCredit), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 16),

              // Table
              pw.TableHelper.fromTextArray(
                headers: ['Ticket N°', 'Date', 'Client', 'Mode', 'Total Net', 'Versé', 'Reste'],
                data: ventes.map((v) => [
                  v.ticketNumber.isNotEmpty ? v.ticketNumber : 'VNT-${v.id}',
                  dateFormat.format(v.date),
                  v.clientName ?? 'Occasionnel',
                  v.paymentMethod,
                  formatter.format(v.totalAmount),
                  formatter.format(v.paidAmount),
                  formatter.format(v.remainingAmount),
                ]).toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
                cellStyle: const pw.TextStyle(fontSize: 8),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
                rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5))),
              ),
            ];
          },
        ),
      );

      final pdfBytes = await pdf.save();

      Directory targetDir;
      if (Platform.isAndroid) {
        final downloadDir = Directory('/storage/emulated/0/Download');
        if (await downloadDir.exists()) {
          targetDir = downloadDir;
        } else {
          targetDir = await getApplicationDocumentsDirectory();
        }
      } else {
        targetDir = await getApplicationDocumentsDirectory();
      }

      final fileName = 'Rapport_Ventes_${periodLabel.replaceAll(' ', '_')}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
      final filePath = p.join(targetDir.path, fileName);
      final file = File(filePath);
      await file.writeAsBytes(pdfBytes);

      if (context.mounted) {
        AppToast.showSuccess(context, 'Rapport PDF enregistré dans : ${file.path}');
      }

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Rapport de ventes PDF ($periodLabel)',
      );
    } catch (e) {
      if (context.mounted) {
        AppToast.showError(context, 'Erreur de génération du rapport PDF : $e');
      }
    }
  }
}
