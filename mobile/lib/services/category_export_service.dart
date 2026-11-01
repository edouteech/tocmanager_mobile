import 'dart:io';
import 'package:excel/excel.dart' as xl;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../providers/settings_provider.dart';
import '../widgets/app_toast.dart';

class CategoryExportService {
  static Future<void> exportCategoriesExcel(
    BuildContext context,
    List<Category> categories,
    List<Product> products,
  ) async {
    final excel = xl.Excel.createExcel();
    final xl.Sheet sheet = excel['Catégories'];

    sheet.appendRow([xl.TextCellValue('RÉPERTOIRE DES CATÉGORIES')]);
    sheet.appendRow([xl.TextCellValue('')]);

    sheet.appendRow([
      xl.TextCellValue('ID'),
      xl.TextCellValue('Nom de la catégorie'),
      xl.TextCellValue('Description'),
      xl.TextCellValue('Nombre de produits'),
      xl.TextCellValue('Créé le'),
    ]);

    final dateFmt = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR');

    for (final cat in categories) {
      final pCount = products.where((p) => p.categoryId == cat.id).length;
      sheet.appendRow([
        xl.IntCellValue(cat.id ?? 0),
        xl.TextCellValue(cat.name),
        xl.TextCellValue(cat.description ?? '—'),
        xl.IntCellValue(pCount),
        xl.TextCellValue(dateFmt.format(cat.createdAt)),
      ]);
    }

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
      final file = File('${downloadsDir!.path}/Categories_$timestamp.xlsx');
      await file.writeAsBytes(fileBytes);

      if (context.mounted) {
        AppToast.showSuccess(context, 'Fichier Excel généré : ${file.path.split('/').last}');
        await Share.shareXFiles([XFile(file.path)], text: 'Export des Catégories — TOC Manager');
      }
    }
  }

  static Future<void> exportCategoriesPdfReport(
    BuildContext context,
    List<Category> categories,
    List<Product> products,
    StoreSettings settings,
  ) async {
    final pdf = pw.Document();
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        header: (pw.Context ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        settings.name.toUpperCase(),
                        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                      ),
                      if (settings.phone.isNotEmpty)
                        pw.Text('Tél : ${settings.phone}', style: const pw.TextStyle(fontSize: 8)),
                      if (settings.address.isNotEmpty)
                        pw.Text(settings.address, style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'RÉPERTOIRE DES CATÉGORIES',
                        style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text('Date : ${dateFmt.format(DateTime.now())}',
                          style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 10),
            ],
          );
        },
        build: (pw.Context ctx) {
          return [
            pw.TableHelper.fromTextArray(
              headers: ['ID', 'Nom', 'Description', 'Produits', 'Créé le'],
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
              cellStyle: const pw.TextStyle(fontSize: 8),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
              cellAlignment: pw.Alignment.centerLeft,
              data: categories.map((c) {
                final pCount = products.where((p) => p.categoryId == c.id).length;
                return [
                  c.id?.toString() ?? '—',
                  c.name,
                  c.description ?? '—',
                  pCount.toString(),
                  dateFmt.format(c.createdAt),
                ];
              }).toList(),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Repertoire_Categories_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }
}
