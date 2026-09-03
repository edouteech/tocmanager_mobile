import 'dart:io';
import 'package:excel/excel.dart' as xl;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/decaissement.dart';
import '../providers/settings_provider.dart';
import '../widgets/app_toast.dart';

class DecaissementExportService {
  static Future<void> exportDecaissementsExcel(
    BuildContext context,
    List<Decaissement> decaissements,
    String periodName,
  ) async {
    final excel = xl.Excel.createExcel();
    final xl.Sheet sheet = excel['Dépenses'];

    // Title
    sheet.appendRow([xl.TextCellValue('REGISTRE DES DÉPENSES / DÉCAISSEMENTS - $periodName')]);
    sheet.appendRow([xl.TextCellValue('')]);

    // Headers
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

    // Totals row
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

    Directory? downloadsDir;
    if (Platform.isAndroid) {
      downloadsDir = Directory('/storage/emulated/0/Download');
      if (!await downloadsDir.exists()) {
        downloadsDir = await getExternalStorageDirectory();
      }
    } else {
      downloadsDir = await getApplicationDocumentsDirectory();
    }

    final fileBytes = excel.save();
    if (fileBytes != null) {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${downloadsDir!.path}/Depenses_$timestamp.xlsx');
      await file.writeAsBytes(fileBytes);

      if (context.mounted) {
        AppToast.showSuccess(context, 'Fichier Excel généré : ${file.path.split('/').last}');
        await Share.shareXFiles([XFile(file.path)], text: 'Registre des Dépenses');
      }
    }
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

    final double totalExpenses = decaissements.fold(0.0, (sum, d) => sum + d.amount);

    // Group expenses by category
    final Map<String, double> byCategory = {};
    for (final d in decaissements) {
      byCategory[d.category] = (byCategory[d.category] ?? 0) + d.amount;
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context ctx) => [
          // Header
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(settings.name.toUpperCase(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                  if (settings.phone.isNotEmpty) pw.Text('Tél: ${settings.phone}', style: const pw.TextStyle(fontSize: 10)),
                  if (settings.address.isNotEmpty) pw.Text(settings.address, style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('RAPPORT DES DÉPENSES', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12, color: PdfColors.red900)),
                  pw.Text('Période : $periodName', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text('Édité le : ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Divider(thickness: 1),
          pw.SizedBox(height: 12),

          // Summary Card
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

          // Breakdown by Category
          if (byCategory.isNotEmpty) ...[
            pw.Text('Répartition par Catégorie :', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
            pw.SizedBox(height: 6),
            pw.TableHelper.fromTextArray(
              headers: ['Catégorie', 'Montant Total (F)', 'Part (%)'],
              data: byCategory.entries.map((e) {
                final pct = totalExpenses > 0 ? (e.value / totalExpenses) * 100 : 0.0;
                return [
                  e.key,
                  formatter.format(e.value),
                  '${pct.toStringAsFixed(1)} %',
                ];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 9),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey800),
              rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5))),
              cellStyle: const pw.TextStyle(fontSize: 9),
            ),
            pw.SizedBox(height: 16),
          ],

          // Expenses details list
          pw.Text('Détail des Décaissements :', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
          pw.SizedBox(height: 6),
          pw.TableHelper.fromTextArray(
            headers: ['Date', 'Description', 'Catégorie', 'Référence', 'Montant (F)'],
            data: decaissements.map((d) {
              return [
                dateFormat.format(d.date),
                d.description,
                d.category,
                d.reference ?? '—',
                formatter.format(d.amount),
              ];
            }).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 9),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.red800),
            rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5))),
            cellStyle: const pw.TextStyle(fontSize: 9),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Rapport_Depenses.pdf',
    );
  }
}
