import 'dart:io';
import 'package:excel/excel.dart' as xl;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/client.dart';
import '../providers/settings_provider.dart';
import '../widgets/app_toast.dart';

class ClientExportService {
  static Future<void> exportClientsExcel(
    BuildContext context,
    List<Client> clients,
    String periodName,
  ) async {
    final excel = xl.Excel.createExcel();
    final xl.Sheet sheet = excel['Clients'];

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
      final file = File('${downloadsDir!.path}/Registre_Clients_$timestamp.xlsx');
      await file.writeAsBytes(fileBytes);

      if (context.mounted) {
        AppToast.showSuccess(context, 'Fichier Excel généré : ${file.path.split('/').last}');
        await Share.shareXFiles([XFile(file.path)], text: 'Registre des Clients & Créances');
      }
    }
  }

  static Future<void> exportClientsPdfReport(
    BuildContext context,
    List<Client> clients,
    String periodName,
    StoreSettings settings,
  ) async {
    final pdf = pw.Document();
    final formatter = NumberFormat.currency(locale: 'fr_FR', symbol: 'F', decimalDigits: 0);

    final double totalDebt = clients.fold(0.0, (sum, c) => sum + (c.balance > 0 ? c.balance : 0));
    final debtClientsCount = clients.where((c) => c.balance > 0).length;

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
                  pw.Text('RAPPORT CLIENTS & CRÉANCES', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12, color: PdfColors.blue900)),
                  pw.Text('Filtre : $periodName', style: const pw.TextStyle(fontSize: 10)),
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
              _pdfMetricCard('Nombre Total Clients', '${clients.length}', PdfColors.blue800),
              pw.SizedBox(width: 10),
              _pdfMetricCard('Clients Endettés', '$debtClientsCount', PdfColors.orange800),
              pw.SizedBox(width: 10),
              _pdfMetricCard('Total Créances Dues', formatter.format(totalDebt), PdfColors.red800),
            ],
          ),
          pw.SizedBox(height: 16),

          pw.TableHelper.fromTextArray(
            headers: ['Client', 'Téléphone', 'Email', 'Statut', 'Solde Créance (F)'],
            data: clients.map((c) {
              return [
                c.name,
                c.phone ?? '—',
                c.email ?? '—',
                c.balance > 0 ? 'Créance en cours' : 'À jour',
                c.balance > 0 ? formatter.format(c.balance) : '0 F',
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
      name: 'Rapport_Clients_Creances.pdf',
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
