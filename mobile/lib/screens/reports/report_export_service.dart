import 'dart:io';
import 'package:excel/excel.dart' as xl;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/date_filter_period.dart';
import '../../providers/decaissement_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/vente_provider.dart';
import 'report_widgets.dart';

class ReportExportService {
  static Future<void> exportPdf(BuildContext context, DateFilterPeriod period) async {
    try {
      final doc = pw.Document();
      final numFmt = NumberFormat('#,##0', 'fr_FR');
      final dateFmt = DateFormat('dd/MM/yyyy HH:mm');
      final venteProv = context.read<VenteProvider>();
      final decaissementProv = context.read<DecaissementProvider>();
      final currencyCode = context.read<SettingsProvider>().settings.currency;
      final curSym = reportCurrencySymbol(currencyCode);
      final now = DateTime.now();

      final ventes = venteProv.items.where((v) => period.matches(v.date)).toList();
      final decaissements = decaissementProv.items.where((d) => period.matches(d.date)).toList();
      final ca = ventes.fold(0.0, (sum, v) => sum + v.totalAmount);
      final depenses = decaissements.fold(0.0, (sum, d) => sum + d.amount);
      final net = ca - depenses;

      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context ctx) => pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Rapport Financier Synthétique',
                    style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 4),
                pw.Text('Période : ${period.label}',
                    style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800)),
                pw.Text('Généré le ${dateFmt.format(now)}',
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                pw.Divider(),
                pw.SizedBox(height: 14),
                pw.Text('Résumé des opérations :',
                    style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                pw.Bullet(text: 'Chiffre d\'Affaires (Ventes) : ${numFmt.format(ca)} $curSym'),
                pw.Bullet(text: 'Total Décaissements (Dépenses) : ${numFmt.format(depenses)} $curSym'),
                pw.Bullet(text: 'Résultat Net : ${numFmt.format(net)} $curSym'),
              ],
            ),
          ),
        ),
      );

      await Printing.sharePdf(
        bytes: await doc.save(),
        filename: 'rapport_financier_${DateFormat('yyyyMMdd').format(now)}.pdf',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur d\'export PDF: $e')));
      }
    }
  }

  static Future<void> exportExcel(BuildContext context, DateFilterPeriod period) async {
    try {
      final excel = xl.Excel.createExcel();
      excel.rename('Sheet1', 'Rapport');
      final sheet = excel['Rapport'];

      final venteProv = context.read<VenteProvider>();
      final decaissementProv = context.read<DecaissementProvider>();
      final currencyCode = context.read<SettingsProvider>().settings.currency;
      final now = DateTime.now();
      final dateFmt = DateFormat('dd/MM/yyyy HH:mm');

      final ventes = venteProv.items.where((v) => period.matches(v.date)).toList();
      final decaissements = decaissementProv.items.where((d) => period.matches(d.date)).toList();

      sheet.appendRow([xl.TextCellValue('Rapport Financier TocManager')]);
      sheet.appendRow([xl.TextCellValue('Période: ${period.label}')]);
      sheet.appendRow([xl.TextCellValue('Généré le: ${dateFmt.format(now)}')]);
      sheet.appendRow([]);
      sheet.appendRow([xl.TextCellValue('Indicateur'), xl.TextCellValue('Montant ($currencyCode)')]);

      final ca = ventes.fold(0.0, (sum, v) => sum + v.totalAmount);
      final depenses = decaissements.fold(0.0, (sum, d) => sum + d.amount);
      sheet.appendRow([xl.TextCellValue('Chiffre d\'Affaires'), xl.DoubleCellValue(ca)]);
      sheet.appendRow([xl.TextCellValue('Total Dépenses'), xl.DoubleCellValue(depenses)]);
      sheet.appendRow([xl.TextCellValue('Trésorerie Nette'), xl.DoubleCellValue(ca - depenses)]);

      final bytes = excel.encode();
      if (bytes != null) {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/rapport_${now.millisecondsSinceEpoch}.xlsx');
        await file.writeAsBytes(bytes);
        await Share.shareXFiles([XFile(file.path)], text: 'Rapport financier TocManager');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur d\'export Excel: $e')));
      }
    }
  }
}
