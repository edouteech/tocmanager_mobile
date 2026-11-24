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
import '../../models/category.dart';
import '../../models/product.dart';
import '../../providers/category_provider.dart';
import '../../providers/settings_provider.dart';
import '../../theme/app_theme.dart';

void showProductExportSheet(BuildContext context, List<Product> products) {
  final cats = context.read<CategoryProvider>().categories;
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Exporter ${products.length} produit${products.length > 1 ? 's' : ''}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark),
            ),
            const SizedBox(height: 4),
            const Text("Choisissez le format d'export", style: TextStyle(color: AppColors.textMedium, fontSize: 12)),
            const SizedBox(height: 12),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.table_chart_outlined, color: AppColors.success),
              title: const Text('Excel (.xlsx)', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Microsoft Excel, LibreOffice, Google Sheets'),
              onTap: () {
                Navigator.pop(ctx);
                _exportProductsExcel(context, products, cats);
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined, color: AppColors.danger),
              title: const Text('PDF', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Prêt à imprimer ou partager'),
              onTap: () {
                Navigator.pop(ctx);
                _exportProductsPdf(context, products, cats);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    ),
  );
}

Future<void> _exportProductsExcel(
  BuildContext context,
  List<Product> products,
  List<Category> categories,
) async {
  try {
    final excel = xl.Excel.createExcel();
    excel.rename('Sheet1', 'Produits');
    final sheet = excel['Produits'];

    sheet.appendRow([
      'ID', 'Nom', 'Catégorie', "Prix d'achat (F)", 'Prix de vente (F)',
      'Quantité', 'Stock min.', 'Coût stock (F)', 'Valeur vente (F)', 'Statut', 'Créé le',
    ].map(xl.TextCellValue.new).toList());

    final featureEnabled = context.read<SettingsProvider>().settings.enableAverageCostPrice;
    final dateFmt = DateFormat('dd/MM/yyyy');
    for (final p in products) {
      final cat = categories.where((c) => c.id == p.categoryId).firstOrNull;
      final status = p.quantity == 0 ? 'Rupture' : p.isLowStock ? 'Stock faible' : 'En stock';
      final effectiveCost = p.effectiveCostPrice(featureEnabled);
      sheet.appendRow([
        xl.IntCellValue(p.id ?? 0),
        xl.TextCellValue(p.name),
        xl.TextCellValue(cat?.name ?? ''),
        xl.DoubleCellValue(effectiveCost),
        xl.DoubleCellValue(p.price),
        xl.DoubleCellValue(p.quantity),
        xl.DoubleCellValue(p.alertQuantity),
        xl.DoubleCellValue(p.quantity * effectiveCost),
        xl.DoubleCellValue(p.stockSaleValue),
        xl.TextCellValue(status),
        xl.TextCellValue(dateFmt.format(p.createdAt)),
      ]);
    }

    final bytes = excel.encode();
    if (bytes == null) throw Exception('Échec encodage');

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/produits_${DateTime.now().millisecondsSinceEpoch}.xlsx');
    await file.writeAsBytes(bytes);

    await Share.shareXFiles([XFile(file.path)], text: 'Export produits — tocmanager');
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur export: $e'), backgroundColor: AppColors.danger),
      );
    }
  }
}

Future<void> _exportProductsPdf(
  BuildContext context,
  List<Product> products,
  List<Category> categories,
) async {
  try {
    final featureEnabled = context.read<SettingsProvider>().settings.enableAverageCostPrice;
    final fontRegular = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();
    final doc = pw.Document();
    final numFmt = NumberFormat('#,##0', 'fr_FR');

    final tableData = products.map((p) {
      final cat = categories.where((c) => c.id == p.categoryId).firstOrNull;
      final status = p.quantity == 0 ? 'Rupture' : p.isLowStock ? 'Faible' : 'OK';
      final effectiveCost = p.effectiveCostPrice(featureEnabled);
      return [
        p.name,
        cat?.name ?? '—',
        '${numFmt.format(effectiveCost)} F',
        '${numFmt.format(p.price)} F',
        p.quantity.toStringAsFixed(0),
        '${numFmt.format(p.quantity * effectiveCost)} F',
        '${numFmt.format(p.stockSaleValue)} F',
        status,
      ];
    }).toList();

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.all(24),
      header: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Liste des produits — tocmanager', style: pw.TextStyle(font: fontBold, fontSize: 16)),
          pw.SizedBox(height: 4),
          pw.Text(
            'Généré le ${DateFormat('dd/MM/yyyy à HH:mm').format(DateTime.now())} · ${products.length} produit${products.length > 1 ? 's' : ''}',
            style: pw.TextStyle(font: fontRegular, fontSize: 9, color: PdfColors.grey600),
          ),
          pw.Divider(),
          pw.SizedBox(height: 4),
        ],
      ),
      build: (ctx) => [
        pw.TableHelper.fromTextArray(
          headers: ['Nom', 'Catégorie', 'P. achat', 'P. vente', 'Qté', 'Coût stock', 'Valeur vente', 'Statut'],
          data: tableData,
          headerStyle: pw.TextStyle(font: fontBold, fontSize: 9),
          cellStyle: pw.TextStyle(font: fontRegular, fontSize: 8),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.blue50),
          rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
          oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          columnWidths: const {
            0: pw.FlexColumnWidth(2.2),
            1: pw.FlexColumnWidth(1.4),
            2: pw.FlexColumnWidth(1.1),
            3: pw.FlexColumnWidth(1.1),
            4: pw.FlexColumnWidth(0.7),
            5: pw.FlexColumnWidth(1.3),
            6: pw.FlexColumnWidth(1.3),
            7: pw.FlexColumnWidth(0.9),
          },
        ),
      ],
    ));

    await Printing.sharePdf(
      bytes: await doc.save(),
      filename: 'produits_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur PDF: $e'), backgroundColor: AppColors.danger),
      );
    }
  }
}
