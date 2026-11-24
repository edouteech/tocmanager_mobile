import 'package:excel/excel.dart' as xl;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/approvisionnement.dart';
import '../models/product.dart';
import '../providers/settings_provider.dart';
import 'export_helper.dart';

class ApprovisionnementExportService {
  static Future<void> exportApprovisionnementsExcel(
    BuildContext context,
    List<Approvisionnement> approvisionnements,
    List<Product> products,
    String periodName,
  ) async {
    final excel = xl.Excel.createExcel();
    final sheet = excel['Approvisionnements'];
    sheet.appendRow([xl.TextCellValue('REGISTRE DES APPROVISIONNEMENTS - $periodName')]);
    sheet.appendRow([xl.TextCellValue('')]);
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
    double grandTotal = 0, grandPaid = 0, grandRemaining = 0;

    for (final a in approvisionnements) {
      final p = products.where((item) => item.id == a.productId).firstOrNull;
      grandTotal += a.total;
      grandPaid += a.paidAmount;
      grandRemaining += a.remainingAmount;
      sheet.appendRow([
        xl.IntCellValue(a.id ?? 0),
        xl.TextCellValue(dateFormat.format(a.date)),
        xl.TextCellValue(p?.name ?? 'Produit #${a.productId}'),
        xl.TextCellValue(a.supplier ?? '—'),
        xl.DoubleCellValue(a.quantity),
        xl.DoubleCellValue(a.unitPrice),
        xl.DoubleCellValue(a.total),
        xl.DoubleCellValue(a.paidAmount),
        xl.DoubleCellValue(a.remainingAmount),
        xl.TextCellValue(a.isCredit ? 'Crédit Fournisseur' : 'Payé'),
      ]);
    }

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

    await ExportHelper.saveExcelAndShare(
      context,
      excel: excel,
      fileName: 'Approvisionnements_${DateTime.now().millisecondsSinceEpoch}.xlsx',
      shareText: 'Registre des Approvisionnements',
    );
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

    double grandTotal = 0, grandPaid = 0, grandRemaining = 0;
    for (final a in approvisionnements) {
      grandTotal += a.total;
      grandPaid += a.paidAmount;
      grandRemaining += a.remainingAmount;
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (_) => [
          ExportHelper.buildPdfStoreHeader(
            settings,
            title: 'RAPPORT D\'APPROVISIONNEMENT',
            subtitle: 'Période : $periodName',
          ),
          pw.Row(
            children: [
              ExportHelper.buildPdfMetricCard('Total Achats Stock', formatter.format(grandTotal), PdfColors.blue800),
              pw.SizedBox(width: 10),
              ExportHelper.buildPdfMetricCard('Total Réglé', formatter.format(grandPaid), PdfColors.green800),
              pw.SizedBox(width: 10),
              ExportHelper.buildPdfMetricCard('Reste à Payer (Dette)', formatter.format(grandRemaining), PdfColors.orange800),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: ['Date', 'Produit', 'Fournisseur', 'Qté', 'P.U.', 'Total Net', 'Montant Dû'],
            data: approvisionnements.map((a) {
              final p = products.where((item) => item.id == a.productId).firstOrNull;
              final qStr = a.quantity.toStringAsFixed(a.quantity.truncateToDouble() == a.quantity ? 0 : 1);
              return [
                dateFormat.format(a.date),
                p?.name ?? 'Produit #${a.productId}',
                a.supplier ?? '—',
                '$qStr ${p?.unit ?? 'pce'}',
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
    await ExportHelper.layoutPdf(pdf, 'Rapport_Approvisionnements.pdf');
  }
}
