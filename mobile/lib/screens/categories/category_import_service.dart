import 'package:excel/excel.dart' as xl;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/category.dart';
import '../../providers/category_provider.dart';
import '../../providers/product_provider.dart';
import '../../widgets/app_toast.dart';
import 'category_import_preview_sheet.dart';

const List<Color> kCategoryPalette = [
  Color(0xFF29ABE2),
  Color(0xFF27AE60),
  Color(0xFFF39C12),
  Color(0xFFE74C3C),
  Color(0xFF8E44AD),
  Color(0xFF1ABC9C),
  Color(0xFF2C3E50),
  Color(0xFFE67E22),
];

const List<IconData> kCategoryIcons = [
  Icons.inventory_2,
  Icons.phone_android,
  Icons.restaurant,
  Icons.checkroom,
  Icons.business_center,
  Icons.local_pharmacy,
  Icons.directions_car,
  Icons.computer,
  Icons.construction,
  Icons.school,
  Icons.home,
  Icons.sports_soccer,
];

Future<void> importCategoriesFromExcel(BuildContext context) async {
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
        AppToast.showError(context, 'Fichier vide ou sans données.');
      }
      return;
    }

    int colName = 0;
    int colDesc = 1;
    if (sheet.rows.isNotEmpty) {
      final header = sheet.rows[0];
      for (var c = 0; c < header.length; c++) {
        final title = header[c]?.value?.toString().toLowerCase().trim() ?? '';
        if (title.contains('nom') ||
            title.contains('catégorie') ||
            title.contains('categorie') ||
            title.contains('libellé') ||
            title == 'titre') {
          colName = c;
        } else if (title.contains('desc')) {
          colDesc = c;
        }
      }
    }

    final toImport = <Map<String, String>>[];
    for (var i = 1; i < sheet.rows.length; i++) {
      final row = sheet.rows[i];
      final name = (row.length > colName ? row[colName]?.value?.toString() : null)?.trim() ?? '';
      if (name.isEmpty) continue;
      final desc = (colDesc >= 0 && row.length > colDesc)
          ? (row[colDesc]?.value?.toString().trim() ?? '')
          : '';
      toImport.add({'name': name, 'description': desc});
    }

    if (toImport.isEmpty) {
      if (context.mounted) {
        AppToast.showError(context, 'Aucune catégorie valide trouvée.');
      }
      return;
    }

    if (!context.mounted) return;
    showCategoryImportPreviewSheet(context, toImport, _confirmCategoriesImport);
  } catch (e) {
    if (context.mounted) {
      AppToast.showError(context, 'Erreur de lecture du fichier Excel: $e');
    }
  }
}

Future<void> _confirmCategoriesImport(
  BuildContext context,
  List<Map<String, String>> rows,
) async {
  final catProvider = context.read<CategoryProvider>();
  final existingNames = {
    for (final c in catProvider.categories) c.name.toLowerCase().trim()
  };

  int createdCount = 0;
  for (final r in rows) {
    final key = r['name']!.toLowerCase().trim();
    if (existingNames.contains(key)) continue;

    final color = kCategoryPalette[createdCount % kCategoryPalette.length];
    final newCat = Category(
      name: r['name']!.trim(),
      description: r['description']?.isNotEmpty == true ? r['description'] : null,
      color: color.toARGB32(),
      icon: Icons.category.codePoint,
      createdAt: DateTime.now(),
    );

    await catProvider.add(newCat);
    existingNames.add(key);
    createdCount++;
  }

  if (context.mounted) {
    AppToast.showSuccess(
      context,
      createdCount > 0
          ? '$createdCount catégorie${createdCount > 1 ? 's' : ''} importée${createdCount > 1 ? 's' : ''} avec succès.'
          : 'Aucune nouvelle catégorie à importer (toutes déjà existantes).',
    );
    await context.read<ProductProvider>().load();
  }
}
