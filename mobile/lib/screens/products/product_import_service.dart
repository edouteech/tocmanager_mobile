import 'package:excel/excel.dart' as xl;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'product_import_preview_sheet.dart';

Future<void> importProductsFromExcel(BuildContext context) async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['xlsx'],
    withData: true,
  );
  if (result == null || result.files.single.bytes == null) return;

  try {
    final excel = xl.Excel.decodeBytes(result.files.single.bytes!);
    final sheetName = excel.tables.keys.first;
    final sheet = excel.tables[sheetName]!;

    if (sheet.rows.length < 2) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fichier vide ou sans données.')),
        );
      }
      return;
    }

    double parseNum(List<xl.Data?> row, int col) {
      if (col < 0 || row.length <= col) return 0;
      final v = row[col]?.value;
      if (v is xl.IntCellValue) return v.value.toDouble();
      if (v is xl.DoubleCellValue) return v.value;
      final s = v?.toString().replaceAll(' ', '').replaceAll(',', '.') ?? '';
      return double.tryParse(s) ?? 0;
    }

    int colName = -1;
    int colCat = -1;
    int colCost = -1;
    int colPrice = -1;
    int colQty = -1;
    int colAlert = -1;
    int colTotalCost = -1;
    int colTotalPrice = -1;

    if (sheet.rows.isNotEmpty) {
      final header = sheet.rows[0];
      for (var c = 0; c < header.length; c++) {
        final title = header[c]?.value?.toString().toLowerCase().trim() ?? '';
        if (title.isEmpty) continue;

        final isTotalColumn = title.contains('coût stock') ||
            title.contains('cout stock') ||
            title.contains('valeur stock') ||
            title.contains('valeur vente') ||
            title.contains('prix total') ||
            title.contains('coût total') ||
            title.contains('cout total') ||
            title.contains('montant total') ||
            title.contains('valeur totale') ||
            title.contains('valeur total') ||
            title.contains('total ht') ||
            title.contains('total ttc');

        if (isTotalColumn) {
          if (title.contains('coût') || title.contains('cout') || title.contains('achat')) {
            colTotalCost = c;
          } else if (title.contains('vente') || title.contains('prix') || title.contains('valeur')) {
            colTotalPrice = c;
          }
          continue;
        }

        if (title.contains('nom') ||
            title.contains('désignation') ||
            title.contains('designation') ||
            title.contains('produit') ||
            title == 'libellé' ||
            title == 'libelle' ||
            title == 'name' ||
            title == 'article') {
          colName = c;
        } else if (title.contains('catégorie') || title.contains('categorie') || title == 'cat') {
          colCat = c;
        } else if (title.contains('min') || title.contains('alerte') || title.contains('seuil')) {
          colAlert = c;
        } else if (title.contains('achat') ||
            (title.contains('coût') && !title.contains('stock')) ||
            (title.contains('cout') && !title.contains('stock')) ||
            title.contains('revient') ||
            title == 'p.u. achat' ||
            title == 'pu achat') {
          colCost = c;
        } else if (title.contains('vente') ||
            title.contains('prix') ||
            title == 'p.u.' ||
            title == 'pu' ||
            title == 'prix unitaire') {
          colPrice = c;
        } else if (title.contains('quantité') ||
            title.contains('quantite') ||
            title.contains('stock') ||
            title == 'qte' ||
            title == 'qty') {
          colQty = c;
        }
      }
    }

    if (colName < 0) {
      colName = 1;
      colCat = 2;
      colCost = 3;
      colPrice = 4;
      colQty = 5;
      colAlert = 6;
    }

    final toImport = <Map<String, dynamic>>[];
    for (var i = 1; i < sheet.rows.length; i++) {
      final row = sheet.rows[i];
      final name = (colName >= 0 && row.length > colName ? row[colName]?.value?.toString() : null)?.trim() ?? '';
      if (name.isEmpty) continue;

      final double qty = parseNum(row, colQty);
      double costPrice = parseNum(row, colCost);
      double price = parseNum(row, colPrice);
      final double alertQty = parseNum(row, colAlert);

      if (costPrice == 0 && colTotalCost >= 0 && qty > 0) {
        final totalCost = parseNum(row, colTotalCost);
        if (totalCost > 0) costPrice = totalCost / qty;
      }
      if (price == 0 && colTotalPrice >= 0 && qty > 0) {
        final totalPrice = parseNum(row, colTotalPrice);
        if (totalPrice > 0) price = totalPrice / qty;
      }

      toImport.add({
        'name': name,
        'category': (colCat >= 0 && row.length > colCat) ? (row[colCat]?.value?.toString().trim() ?? '') : '',
        'costPrice': costPrice,
        'price': price,
        'quantity': qty,
        'alertQuantity': alertQty,
      });
    }

    if (toImport.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Aucune ligne valide trouvée.')));
      }
      return;
    }

    if (!context.mounted) return;
    showProductImportPreviewSheet(context, toImport);
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de lecture: $e'), backgroundColor: AppColors.danger),
      );
    }
  }
}
