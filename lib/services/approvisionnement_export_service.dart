import 'dart:io';
import 'package:excel/excel.dart' as xl;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/approvisionnement.dart';
import '../models/product.dart';
import '../providers/settings_provider.dart';
import '../widgets/app_toast.dart';

class ApprovisionnementExportService {
  static Future<void> exportApprovisionnementsExcel(
    BuildContext context,
    List<Approvisionnement> approvisionnements,
    List<Product> products,
    String periodName,
  ) async {
    final excel = xl.Excel.createExcel();
    final xl.Sheet sheet = excel['Approvisionnements'];

    // Title row
    sheet.appendRow([
      xl.TextCellValue('REGISTRE DES APPROVISIONNEMENTS - $periodName'),
    ]);
    sheet.appendRow([xl.TextCellValue('')]);

    // Headers
    sheet.appendRow([
      xl.TextCellValue('ID'),
      xl.TextCellValue('Date'),
      xl.TextCellValue('Produit'),
      xl.TextCellValue('Fournisseur'),
      xl.TextCellValue('Quantité'),
      xl.TextCellValue('Prix unitaire (F)'),
      xl.TextCellValue('Total (F)'),
      xl.TextCellValue('Montant Payé (F)'),
      xl.TextCellValue('Reste à Payer (F)'),
      xl.TextCellValue('Statut'),
    ]);

    final dateFormat = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR');

    double grandTotal = 0;
    double grandPaid = 0;
    double grandRemaining = 0;

    for (final a in approvisionnements) {
      final p = products.where((item) => item.id == a.productId).firstOrNull;
      final productName = p?.name ?? 'Produit #${a.productId}';
      final supplierName = a.supplier ?? '—';
      final isCredit = a.isCredit;

      grandTotal += a.total;
      grandPaid += a.paidAmount;
      grandRemaining += a.remainingAmount;

      sheet.appendRow([
        xl.IntCellValue(a.id ?? 0),
        xl.TextCellValue(dateFormat.format(a.date)),
        xl.TextCellValue(productName),
        xl.TextCellValue(supplierName),
        xl.DoubleCellValue(a.quantity),
        xl.DoubleCellValue(a.unitPrice),
        xl.DoubleCellValue(a.total),
        xl.DoubleCellValue(a.paidAmount),
        xl.DoubleCellValue(a.remainingAmount),
        xl.TextCellValue(isCredit ? 'Crédit Fournisseur' : 'Payé'),
      ]);
    }

    // Totals row
    sheet.appendRow([xl.TextCellValue('')]);
    sheet.appendRow([
      xl.TextCellValue('TOTAUX'),
      xl.TextCellValue(''),
      xl.TextCellValue(''),
      xl.TextCellValue(''),
      xl.TextCellValue(''),
      xl.TextCellValue(''),
      xl.DoubleCellValue(grandTotal),
      xl.DoubleCellValue(grandPaid),
      xl.DoubleCellValue(grandRemaining),
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
      final file = File('${downloadsDir!.path}/Approvisionnements_$timestamp.xlsx');
      await file.writeAsBytes(fileBytes);

      if (context.mounted) {
        AppToast.showSuccess(context, 'Fichier Excel généré : ${file.path.split('/').last}');
        await Share.shareXFiles([XFile(file.path)], text: 'Registre des Approvisionnements');
      }
    }
  }

  static Future<void> exportApprovisionnementsPdfReport(
    BuildContext context,
    List<Approvisionnement> approvisionnements,
    List<Product> products,
    String periodName,
    StoreSettings settings,
  ) async {
    final pdf = pw.Document();
    final formatter = NumberFormat.currency(locale: 'fr_FR', symbol: 'F', decimalDigits: 0);
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR');

    double grandTotal = 0;
    double grandPaid = 0;
    double grandRemaining = 0;

    for (final a in approvisionnements) {
      grandTotal += a.total;
      grandPaid += a.paidAmount;
      grandRemaining += a.remainingAmount;
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
                  pw.Text('RAPPORT D\'APPROVISIONNEMENT', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12, color: PdfColors.blue900)),
                  pw.Text('Période : $periodName', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text('Édité le : ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Divider(thickness: 1),
          pw.SizedBox(height: 12),

          // Summary Metrics Cards
          pw.Row(
            children: [
              _pdfMetricCard('Total Achats Stock', formatter.format(grandTotal), PdfColors.blue800),
              pw.SizedBox(width: 10),
              _pdfMetricCard('Total Réglé', formatter.format(grandPaid), PdfColors.green800),
              pw.SizedBox(width: 10),
              _pdfMetricCard('Reste à Payer (Dette)', formatter.format(grandRemaining), PdfColors.orange800),
            ],
          ),
          pw.SizedBox(height: 16),

          // Table of entries
          pw.TableHelper.fromTextArray(
            headers: ['Date', 'Produit', 'Fournisseur', 'Qté', 'P.U.', 'Total Net', 'Montant Dû'],
            data: approvisionnements.map((a) {
              final p = products.where((item) => item.id == a.productId).firstOrNull;
              final productName = p?.name ?? 'Produit #${a.productId}';
              return [
                dateFormat.format(a.date),
                productName,
                a.supplier ?? '—',
                '${a.quantity.toStringAsFixed(a.quantity.truncateToDouble() == a.quantity ? 0 : 1)} ${p?.unit ?? 'pce'}',
                formatter.format(a.unitPrice),
                formatter.format(a.total),
                a.isCredit ? formatter.format(a.remainingAmount) : 'Payé',
              ];
            }).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 9),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
            rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5))),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellAlignment: pw.Alignment.centerLeft,
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Rapport_Approvisionnements.pdf',
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
