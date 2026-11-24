import 'package:excel/excel.dart' as xl;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/category.dart';
import '../models/product.dart';
import '../providers/settings_provider.dart';
import 'export_helper.dart';

class CategoryExportService {
  static Future<void> exportCategoriesExcel(
    BuildContext context,
    List<Category> categories,
    List<Product> products,
  ) async {
    final excel = xl.Excel.createExcel();
    final sheet = excel['Catégories'];
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

    await ExportHelper.saveExcelAndShare(
      context,
      excel: excel,
      fileName: 'Categories_${DateTime.now().millisecondsSinceEpoch}.xlsx',
      shareText: 'Export des Catégories — TOC Manager',
    );
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
        header: (_) => ExportHelper.buildPdfStoreHeader(
          settings,
          title: 'RÉPERTOIRE DES CATÉGORIES',
          subtitle: 'Date : ${dateFmt.format(DateTime.now())}',
          titleColor: PdfColors.black,
        ),
        build: (_) => [
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
        ],
      ),
    );
    await ExportHelper.layoutPdf(
      pdf,
      'Repertoire_Categories_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }
}
