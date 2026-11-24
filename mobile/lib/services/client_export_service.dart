import 'package:excel/excel.dart' as xl;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/client.dart';
import '../providers/settings_provider.dart';
import 'export_helper.dart';

class ClientExportService {
  static Future<void> exportClientsExcel(
    BuildContext context,
    List<Client> clients,
    String periodName,
  ) async {
    final excel = xl.Excel.createExcel();
    final sheet = excel['Clients'];
    sheet.appendRow([xl.TextCellValue('REGISTRE DES CLIENTS & CRÉANCES - $periodName')]);
    sheet.appendRow([xl.TextCellValue('')]);
    sheet.appendRow([
      xl.TextCellValue('ID'),
      xl.TextCellValue('Nom du Client'),
      xl.TextCellValue('Téléphone'),
      xl.TextCellValue('Email'),
      xl.TextCellValue('Adresse'),
      xl.TextCellValue('Solde Débiteur / Créance (F)'),
      xl.TextCellValue('Statut'),
    ]);

    double totalDebt = 0;
    for (final c in clients) {
      totalDebt += c.balance;
      sheet.appendRow([
        xl.IntCellValue(c.id ?? 0),
        xl.TextCellValue(c.name),
        xl.TextCellValue(c.phone ?? '—'),
        xl.TextCellValue(c.email ?? '—'),
        xl.TextCellValue(c.address ?? '—'),
        xl.DoubleCellValue(c.balance),
        xl.TextCellValue(c.balance > 0 ? 'Avec Créance' : 'À jour'),
      ]);
    }

    sheet.appendRow([xl.TextCellValue('')]);
    sheet.appendRow([
      xl.TextCellValue('TOTAL CRÉANCES CLIENTS'),
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
      fileName: 'Registre_Clients_${DateTime.now().millisecondsSinceEpoch}.xlsx',
      shareText: 'Registre des Clients & Créances',
    );
  }

  static Future<void> exportClientsPdfReport(
    BuildContext context,
    List<Client> clients,
    String periodName,
    StoreSettings settings,
  ) async {
    final pdf = pw.Document();
    final formatter = NumberFormat.currency(locale: 'fr_FR', symbol: 'F', decimalDigits: 0);
    final totalDebt = clients.fold(0.0, (sum, c) => sum + (c.balance > 0 ? c.balance : 0));
    final debtClientsCount = clients.where((c) => c.balance > 0).length;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (_) => [
          ExportHelper.buildPdfStoreHeader(
            settings,
            title: 'RAPPORT CLIENTS & CRÉANCES',
            subtitle: 'Filtre : $periodName',
          ),
          pw.Row(
            children: [
              ExportHelper.buildPdfMetricCard('Nombre Total Clients', '${clients.length}', PdfColors.blue800),
              pw.SizedBox(width: 10),
              ExportHelper.buildPdfMetricCard('Clients Endettés', '$debtClientsCount', PdfColors.orange800),
              pw.SizedBox(width: 10),
              ExportHelper.buildPdfMetricCard('Total Créances Dues', formatter.format(totalDebt), PdfColors.red800),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: ['Client', 'Téléphone', 'Email', 'Statut', 'Solde Créance (F)'],
            data: clients.map((c) => [
              c.name,
              c.phone ?? '—',
              c.email ?? '—',
              c.balance > 0 ? 'Créance en cours' : 'À jour',
              c.balance > 0 ? formatter.format(c.balance) : '0 F',
            ]).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 9),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
            rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5))),
            cellStyle: const pw.TextStyle(fontSize: 9),
          ),
        ],
      ),
    );
    await ExportHelper.layoutPdf(pdf, 'Rapport_Clients_Creances.pdf');
  }
}
