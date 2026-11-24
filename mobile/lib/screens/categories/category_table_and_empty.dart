import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/category.dart';
import '../../models/product.dart';
import '../../providers/category_provider.dart';
import '../../providers/product_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/category_icon_helper.dart';
import '../category_detail_screen.dart';

class CategoryDataTable extends StatelessWidget {
  final List<Category> categories;
  final List<Product> products;
  final void Function(Category category) onEdit;
  final void Function(Category category) onDelete;

  const CategoryDataTable({
    super.key,
    required this.categories,
    required this.products,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    const h = TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 12);

    return DataTable(
      headingRowHeight: 44,
      dataRowMinHeight: 60,
      dataRowMaxHeight: 60,
      columnSpacing: 16,
      horizontalMargin: 14,
      headingRowColor: WidgetStateProperty.all(AppColors.primaryLight),
      dividerThickness: 1,
      columns: const [
        DataColumn(label: SizedBox(width: 36)),
        DataColumn(label: SizedBox(width: 130, child: Text('Catégorie', style: h))),
        DataColumn(label: SizedBox(width: 160, child: Text('Description', style: h))),
        DataColumn(label: SizedBox(width: 70, child: Center(child: Text('Produits', style: h)))),
        DataColumn(label: SizedBox(width: 76, child: Center(child: Text('Créé le', style: h)))),
        DataColumn(label: SizedBox(width: 110, child: Center(child: Text('Actions', style: h)))),
      ],
      rows: categories.asMap().entries.map((entry) {
        final i = entry.key;
        final cat = entry.value;
        final color = Color(cat.color);
        final count = products.where((p) => p.categoryId == cat.id).length;
        final dateStr =
            '${cat.createdAt.day.toString().padLeft(2, '0')}/'
            '${cat.createdAt.month.toString().padLeft(2, '0')}/'
            '${cat.createdAt.year}';

        return DataRow(
          color: WidgetStateProperty.all(i.isEven ? Colors.white : const Color(0xFFF8FBFF)),
          cells: [
            DataCell(
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: color.withAlpha(35), shape: BoxShape.circle),
                child: Icon(CategoryIconHelper.getIcon(cat.icon), color: color, size: 18),
              ),
            ),
            DataCell(
              Text(
                cat.name,
                style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textDark, fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () => onEdit(cat),
            ),
            DataCell(
              SizedBox(
                width: 160,
                child: Text(
                  cat.description ?? '—',
                  style: const TextStyle(color: AppColors.textMedium, fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            DataCell(
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(20)),
                  child: Text(
                    '$count',
                    style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
              ),
            ),
            DataCell(
              Center(
                child: Text(dateStr, style: const TextStyle(color: AppColors.textLight, fontSize: 11)),
              ),
            ),
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _actionBtn(
                    icon: Icons.visibility_outlined,
                    color: AppColors.success,
                    bg: AppColors.successLight,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => CategoryDetailScreen(category: cat)),
                    ),
                  ),
                  const SizedBox(width: 6),
                  _actionBtn(
                    icon: Icons.edit_outlined,
                    color: AppColors.primary,
                    bg: AppColors.primaryLight,
                    onTap: () => onEdit(cat),
                  ),
                  const SizedBox(width: 6),
                  _actionBtn(
                    icon: Icons.delete_outline,
                    color: AppColors.danger,
                    bg: AppColors.dangerLight,
                    onTap: () => onDelete(cat),
                  ),
                ],
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _actionBtn({
    required IconData icon,
    required Color color,
    required Color bg,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: color, size: 15),
      ),
    );
  }
}

class CategoryEmptyView extends StatelessWidget {
  const CategoryEmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
            child: const Icon(Icons.category_outlined, size: 48, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          const Text(
            'Aucune catégorie',
            style: TextStyle(color: AppColors.textDark, fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          const Text('Créez votre première catégorie', style: TextStyle(color: AppColors.textMedium)),
        ],
      ),
    );
  }
}

void showDeleteCategoryDialog(BuildContext context, Category cat, CategoryProvider provider) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Supprimer', style: TextStyle(fontWeight: FontWeight.w700)),
      content: Text('Supprimer la catégorie "${cat.name}" ?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
        ElevatedButton(
          onPressed: () async {
            await provider.delete(cat.id!);
            if (context.mounted) {
              await context.read<ProductProvider>().load();
            }
            if (ctx.mounted) Navigator.pop(ctx);
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
          child: const Text('Supprimer'),
        ),
      ],
    ),
  );
}
