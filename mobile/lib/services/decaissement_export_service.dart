import 'package:excel/excel.dart' as xl;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/decaissement.dart';
import '../providers/settings_provider.dart';
import 'export_helper.dart';

class DecaissementExportService {
  static Future<void> exportDecaissementsExcel(
    BuildContext context,
    List<Decaissement> decaissements,
    String periodName,
  ) async {
    final excel = xl.Excel.createExcel();
    final sheet = excel['Dépenses'];
    sheet.appendRow([xl.TextCellValue('REGISTRE DES DÉPENSES / DÉCAISSEMENTS - $periodName')]);
    sheet.appendRow([xl.TextCellValue('')]);
    sheet.appendRow([
      xl.TextCellValue('ID'),
      xl.TextCellValue('Date'),
      xl.TextCellValue('Description'),
      xl.TextCellValue('Catégorie'),
      xl.TextCellValue('Montant (F)'),
      xl.TextCellValue('Référence'),
      xl.TextCellValue('Notes'),
    ]);

    final dateFormat = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR');
    double grandTotal = 0;
    for (final d in decaissements) {
      grandTotal += d.amount;
      sheet.appendRow([
        xl.IntCellValue(d.id ?? 0),
        xl.TextCellValue(dateFormat.format(d.date)),
        xl.TextCellValue(d.description),
        xl.TextCellValue(d.category),
        xl.DoubleCellValue(d.amount),
        xl.TextCellValue(d.reference ?? '—'),
        xl.TextCellValue(d.notes ?? '—'),
      ]);
    }

    sheet.appendRow([xl.TextCellValue('')]);
    sheet.appendRow([
      xl.TextCellValue('TOTAL GÉNÉRAL'),
      xl.TextCellValue(''),
      xl.TextCellValue(''),
      xl.TextCellValue(''),
      xl.DoubleCellValue(grandTotal),
      xl.TextCellValue(''),
      xl.TextCellValue(''),
    ]);

    await ExportHelper.saveExcelAndShare(
      context,
      excel: excel,
      fileName: 'Depenses_${DateTime.now().millisecondsSinceEpoch}.xlsx',
      shareText: 'Registre des Dépenses',
    );
  }

  static Future<void> exportDecaissementsPdfReport(
    BuildContext context,
    List<Decaissement> decaissements,
    String periodName,
    StoreSettings settings,
  ) async {
    final pdf = pw.Document();
    final formatter = NumberFormat.currency(locale: 'fr_FR', symbol: 'F', decimalDigits: 0);
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR');
    final totalExpenses = decaissements.fold(0.0, (sum, d) => sum + d.amount);
    final byCategory = <String, double>{};
    for (final d in decaissements) {
      byCategory[d.category] = (byCategory[d.category] ?? 0) + d.amount;
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (_) => [
          ExportHelper.buildPdfStoreHeader(
            settings,
            title: 'RAPPORT DES DÉPENSES',
            subtitle: 'Période : $periodName',
            titleColor: PdfColors.red900,
          ),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.red50,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              border: pw.Border.all(color: PdfColors.red400),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('TOTAL DÉPENSES / FRAIS GÉNÉRAUX :', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: PdfColors.red900)),
                pw.Text(formatter.format(totalExpenses), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14, color: PdfColors.red900)),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
          if (byCategory.isNotEmpty) ...[
            pw.Text('Répartition par Catégorie :', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
            pw.SizedBox(height: 6),
            pw.TableHelper.fromTextArray(
              headers: ['Catégorie', 'Montant Total (F)', 'Part (%)'],
              data: byCategory.entries.map((e) {
                final pct = totalExpenses > 0 ? (e.value / totalExpenses) * 100 : 0.0;
                return [e.key, formatter.format(e.value), '${pct.toStringAsFixed(1)} %'];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 9),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey800),
              rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5))),
              cellStyle: const pw.TextStyle(fontSize: 9),
            ),
            pw.SizedBox(height: 16),
          ],
          pw.Text('Détail des Décaissements :', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
          pw.SizedBox(height: 6),
          pw.TableHelper.fromTextArray(
            headers: ['Date', 'Description', 'Catégorie', 'Référence', 'Montant (F)'],
            data: decaissements.map((d) => [
              dateFormat.format(d.date),
              d.description,
              d.category,
              d.reference ?? '—',
              formatter.format(d.amount),
            ]).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 9),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.red800),
            rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5))),
            cellStyle: const pw.TextStyle(fontSize: 9),
          ),
        ],
      ),
    );
    await ExportHelper.layoutPdf(pdf, 'Rapport_Depenses.pdf');
  }
}
