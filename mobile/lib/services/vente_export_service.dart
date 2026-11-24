import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../models/vente.dart';
import '../providers/settings_provider.dart';
import '../widgets/app_toast.dart';
import 'export_helper.dart';

class VenteExportService {
  static Future<void> exportVentesExcel(
    BuildContext context,
    List<Vente> ventes,
    String periodLabel,
  ) async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel['Ventes'];
      excel.setDefaultSheet('Ventes');

      sheet.appendRow([TextCellValue('REGISTRE DES VENTES - $periodLabel')]);
      sheet.appendRow([TextCellValue('Généré le : ${DateFormat('dd/MM/yyyy HH:mm', 'fr_FR').format(DateTime.now())}')]);
      sheet.appendRow([]);
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

      double totalCA = 0, totalPaye = 0, totalCredit = 0;
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

      sheet.appendRow([]);
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

      final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final safePeriod = periodLabel.replaceAll(' ', '_');
      final file = await ExportHelper.saveExcelAndShare(
        context,
        excel: excel,
        fileName: 'Registre_Ventes_${safePeriod}_$stamp.xlsx',
        shareText: 'Registre des Ventes ($periodLabel)',
        toastPrefix: 'Fichier Excel enregistré dans : ',
        showFullPath: true,
      );
      if (file == null) throw Exception('Impossible d\'engendrer le fichier Excel');
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

      double totalCA = 0, totalEncaisse = 0, totalCredit = 0;
      for (final v in ventes) {
        totalCA += v.totalAmount;
        totalEncaisse += v.paidAmount;
        totalCredit += v.remainingAmount;
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          build: (_) => [
            ExportHelper.buildPdfStoreHeader(
              storeSettings,
              title: 'RAPPORT DE VENTES',
              subtitle: 'Période : $periodLabel',
              titleColor: PdfColors.black,
            ),
            pw.Row(
              children: [
                ExportHelper.buildPdfMetricCard('Total Ventes', '${ventes.length}', PdfColors.grey700),
                pw.SizedBox(width: 8),
                ExportHelper.buildPdfMetricCard('Chiffre d\'Affaires', formatter.format(totalCA), PdfColors.blue800),
                pw.SizedBox(width: 8),
                ExportHelper.buildPdfMetricCard('Encaissé', formatter.format(totalEncaisse), PdfColors.green800),
                pw.SizedBox(width: 8),
                ExportHelper.buildPdfMetricCard('Crédits en cours', formatter.format(totalCredit), PdfColors.orange800),
              ],
            ),
            pw.SizedBox(height: 16),
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
          ],
        ),
      );

      final pdfBytes = await pdf.save();
      final targetDir = await ExportHelper.resolveDownloadsDirectory();
      final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'Rapport_Ventes_${periodLabel.replaceAll(' ', '_')}_$stamp.pdf';
      final file = File(p.join(targetDir.path, fileName));
      await file.writeAsBytes(pdfBytes);

      if (context.mounted) {
        AppToast.showSuccess(context, 'Rapport PDF enregistré dans : ${file.path}');
      }
      await Share.shareXFiles([XFile(file.path)], text: 'Rapport de ventes PDF ($periodLabel)');
    } catch (e) {
      if (context.mounted) {
        AppToast.showError(context, 'Erreur de génération du rapport PDF : $e');
      }
    }
  }
}
