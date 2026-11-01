import 'dart:io';
import 'package:excel/excel.dart' as xl;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/supplier.dart';
import '../providers/settings_provider.dart';
import '../widgets/app_toast.dart';

class SupplierExportService {
  static Future<void> exportSuppliersExcel(
    BuildContext context,
    List<Supplier> suppliers,
    String filterLabel,
  ) async {
    final excel = xl.Excel.createExcel();
    final xl.Sheet sheet = excel['Fournisseurs'];

    sheet.appendRow([xl.TextCellValue('REGISTRE DES FOURNISSEURS & DETTES - $filterLabel')]);
    sheet.appendRow([xl.TextCellValue('')]);

    sheet.appendRow([
      xl.TextCellValue('ID'),
      xl.TextCellValue('Société / Nom'),
      xl.TextCellValue('Contact'),
      xl.TextCellValue('Téléphone'),
      xl.TextCellValue('Email'),
      xl.TextCellValue('Dette Dépensée / Solde (F)'),
      xl.TextCellValue('Statut'),
    ]);

    double totalDebt = 0;

    for (final s in suppliers) {
      totalDebt += s.balance;
      sheet.appendRow([
        xl.IntCellValue(s.id ?? 0),
        xl.TextCellValue(s.name),
        xl.TextCellValue(s.contactPerson ?? '—'),
        xl.TextCellValue(s.phone ?? '—'),
        xl.TextCellValue(s.email ?? '—'),
        xl.DoubleCellValue(s.balance),
        xl.TextCellValue(s.balance > 0 ? 'Dette en cours' : 'À jour'),
      ]);
    }

    sheet.appendRow([xl.TextCellValue('')]);
    sheet.appendRow([
      xl.TextCellValue('TOTAL DETTES FOURNISSEURS'),
      xl.TextCellValue(''),
      xl.TextCellValue(''),
      xl.TextCellValue(''),
      xl.TextCellValue(''),
      xl.DoubleCellValue(totalDebt),
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
      final file = File('${downloadsDir!.path}/Registre_Fournisseurs_$timestamp.xlsx');
      await file.writeAsBytes(fileBytes);

      if (context.mounted) {
        AppToast.showSuccess(context, 'Fichier Excel généré : ${file.path.split('/').last}');
        await Share.shareXFiles([XFile(file.path)], text: 'Registre des Fournisseurs & Dettes');
      }
    }
  }

  static Future<void> exportSuppliersPdfReport(
    BuildContext context,
    List<Supplier> suppliers,
    String filterLabel,
    StoreSettings settings,
  ) async {
    final pdf = pw.Document();
    final formatter = NumberFormat.currency(locale: 'fr_FR', symbol: 'F', decimalDigits: 0);

    final double totalDebt = suppliers.fold(0.0, (sum, s) => sum + (s.balance > 0 ? s.balance : 0));
    final debtSuppliersCount = suppliers.where((s) => s.balance > 0).length;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context ctx) => [
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
                  pw.Text('RAPPORT FOURNISSEURS & DETTES', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12, color: PdfColors.blue900)),
                  pw.Text('Filtre : $filterLabel', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text('Édité le : ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Divider(thickness: 1),
          pw.SizedBox(height: 12),

          pw.Row(
            children: [
              _pdfMetricCard('Total Fournisseurs', '${suppliers.length}', PdfColors.blue800),
              pw.SizedBox(width: 10),
              _pdfMetricCard('Fournisseurs avec Dette', '$debtSuppliersCount', PdfColors.orange800),
              pw.SizedBox(width: 10),
              _pdfMetricCard('Total Dettes Impayées', formatter.format(totalDebt), PdfColors.red800),
            ],
          ),
          pw.SizedBox(height: 16),

          pw.TableHelper.fromTextArray(
            headers: ['Fournisseur', 'Contact', 'Téléphone', 'Statut', 'Solde Dette (F)'],
            data: suppliers.map((s) {
              return [
                s.name,
                s.contactPerson ?? '—',
                s.phone ?? '—',
                s.balance > 0 ? 'Dette en cours' : 'À jour',
                s.balance > 0 ? formatter.format(s.balance) : '0 F',
              ];
            }).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 9),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
            rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5))),
            cellStyle: const pw.TextStyle(fontSize: 9),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Rapport_Fournisseurs_Dettes.pdf',
    );
  }

  static pw.Widget _pdfMetricCard(String label, String value, PdfColor color) {
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
}
