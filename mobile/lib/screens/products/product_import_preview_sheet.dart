import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/category.dart';
import '../../models/product.dart';
import '../../providers/category_provider.dart';
import '../../providers/product_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_toast.dart';

void showProductImportPreviewSheet(BuildContext context, List<Map<String, dynamic>> rows) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) {
      final preview = rows.take(4).toList();
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.upload_file_outlined, color: AppColors.primary),
                const SizedBox(width: 10),
                Text(
                  'Importer ${rows.length} produit${rows.length > 1 ? 's' : ''}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ]),
              const SizedBox(height: 6),
              Text(
                '${rows.length} ligne${rows.length > 1 ? 's' : ''} valide${rows.length > 1 ? 's' : ''} trouvée${rows.length > 1 ? 's' : ''} dans le fichier.',
                style: const TextStyle(color: AppColors.textMedium, fontSize: 13),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              ...preview.map((r) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(children: [
                      const Icon(Icons.chevron_right, size: 16, color: AppColors.textLight),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r['name'] as String,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                overflow: TextOverflow.ellipsis),
                            if ((r['category'] as String).isNotEmpty)
                              Text(r['category'] as String,
                                  style: const TextStyle(fontSize: 11, color: AppColors.textMedium)),
                          ],
                        ),
                      ),
                      Text('Qté: ${(r['quantity'] as double).toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textMedium)),
                      const SizedBox(width: 10),
                      Text('${(r['price'] as double).toStringAsFixed(0)} F',
                          style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
                    ]),
                  )),
              if (rows.length > 4) ...[
                Text('... et ${rows.length - 4} autre${rows.length - 4 > 1 ? 's' : ''}',
                    style: const TextStyle(color: AppColors.textLight, fontSize: 11)),
                const SizedBox(height: 4),
              ],
              const Divider(height: 1),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await confirmProductsImport(context, rows);
                  },
                  child: const Text("Confirmer l'importation"),
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<void> confirmProductsImport(BuildContext context, List<Map<String, dynamic>> rows) async {
  final productProvider = context.read<ProductProvider>();
  final catProvider = context.read<CategoryProvider>();
  final now = DateTime.now();
  int imported = 0;
  int newCatsCreated = 0;

  const palette = [
    Color(0xFF29ABE2),
    Color(0xFF27AE60),
    Color(0xFFF39C12),
    Color(0xFFE74C3C),
    Color(0xFF8E44AD),
    Color(0xFF1ABC9C),
    Color(0xFF2C3E50),
    Color(0xFFE67E22),
  ];

  final Map<String, int> catMap = {};
  for (final c in catProvider.categories) {
    if (c.id != null) catMap[c.name.toLowerCase().trim()] = c.id!;
  }

  for (final row in rows) {
    int? catId;
    final rawCatName = (row['category'] as String).trim();

    if (rawCatName.isNotEmpty) {
      final catKey = rawCatName.toLowerCase();
      if (catMap.containsKey(catKey)) {
        catId = catMap[catKey];
      } else {
        final color = palette[newCatsCreated % palette.length];
        final newCat = Category(
          name: rawCatName,
          color: color.toARGB32(),
          icon: Icons.category.codePoint,
          createdAt: DateTime.now(),
        );
        final newId = await catProvider.add(newCat);
        catMap[catKey] = newId;
        catId = newId;
        newCatsCreated++;
      }
    }

    await productProvider.add(Product(
      name: row['name'] as String,
      categoryId: catId,
      price: row['price'] as double,
      costPrice: row['costPrice'] as double,
      quantity: row['quantity'] as double,
      alertQuantity: (row['alertQuantity'] as double) > 0 ? row['alertQuantity'] as double : 5,
      unit: 'pce',
      createdAt: now,
      updatedAt: now,
    ));
    imported++;
  }

  if (context.mounted) {
    final msg = newCatsCreated > 0
        ? '$imported produit${imported > 1 ? 's' : ''} importé${imported > 1 ? 's' : ''} ($newCatsCreated nouvelle${newCatsCreated > 1 ? 's' : ''} catégorie${newCatsCreated > 1 ? 's' : ''} créée${newCatsCreated > 1 ? 's' : ''}).'
        : '$imported produit${imported > 1 ? 's' : ''} importé${imported > 1 ? 's' : ''} avec succès.';
    AppToast.showSuccess(context, msg);
  }
}
