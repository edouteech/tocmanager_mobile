import 'package:excel/excel.dart' as xl;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/supplier.dart';
import '../providers/settings_provider.dart';
import 'export_helper.dart';

class SupplierExportService {
  static Future<void> exportSuppliersExcel(
    BuildContext context,
    List<Supplier> suppliers,
    String filterLabel,
  ) async {
    final excel = xl.Excel.createExcel();
    final sheet = excel['Fournisseurs'];
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

    await ExportHelper.saveExcelAndShare(
      context,
      excel: excel,
      fileName: 'Registre_Fournisseurs_${DateTime.now().millisecondsSinceEpoch}.xlsx',
      shareText: 'Registre des Fournisseurs & Dettes',
    );
  }

  static Future<void> exportSuppliersPdfReport(
    BuildContext context,
    List<Supplier> suppliers,
    String filterLabel,
    StoreSettings settings,
  ) async {
    final pdf = pw.Document();
    final formatter = NumberFormat.currency(locale: 'fr_FR', symbol: 'F', decimalDigits: 0);
    final totalDebt = suppliers.fold(0.0, (sum, s) => sum + (s.balance > 0 ? s.balance : 0));
    final debtSuppliersCount = suppliers.where((s) => s.balance > 0).length;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (_) => [
          ExportHelper.buildPdfStoreHeader(
            settings,
            title: 'RAPPORT FOURNISSEURS & DETTES',
            subtitle: 'Filtre : $filterLabel',
          ),
          pw.Row(
            children: [
              ExportHelper.buildPdfMetricCard('Total Fournisseurs', '${suppliers.length}', PdfColors.blue800),
              pw.SizedBox(width: 10),
              ExportHelper.buildPdfMetricCard('Fournisseurs avec Dette', '$debtSuppliersCount', PdfColors.orange800),
              pw.SizedBox(width: 10),
              ExportHelper.buildPdfMetricCard('Total Dettes Impayées', formatter.format(totalDebt), PdfColors.red800),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: ['Fournisseur', 'Contact', 'Téléphone', 'Statut', 'Solde Dette (F)'],
            data: suppliers.map((s) => [
              s.name,
              s.contactPerson ?? '—',
              s.phone ?? '—',
              s.balance > 0 ? 'Dette en cours' : 'À jour',
              s.balance > 0 ? formatter.format(s.balance) : '0 F',
            ]).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 9),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
            rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5))),
            cellStyle: const pw.TextStyle(fontSize: 9),
          ),
        ],
      ),
    );
    await ExportHelper.layoutPdf(pdf, 'Rapport_Fournisseurs_Dettes.pdf');
  }
}
