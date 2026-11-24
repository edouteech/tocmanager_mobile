import 'package:flutter/material.dart';
import '../../models/category.dart';
import '../../models/product.dart';
import '../../theme/app_theme.dart';

class ProductDetailSliverAppBar extends StatelessWidget {
  final Product product;
  final Color catColor;
  final Category? category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ProductDetailSliverAppBar({
    super.key,
    required this.product,
    required this.catColor,
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: catColor,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_outlined, color: Colors.white),
          tooltip: 'Modifier',
          onPressed: onEdit,
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.white),
          tooltip: 'Supprimer',
          onPressed: onDelete,
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [catColor.withAlpha(200), catColor],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (category != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(50),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(category!.name, style: const TextStyle(color: Colors.white, fontSize: 11)),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    product.name,
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                  if (product.description != null) ...[
                    const SizedBox(height: 4),
                    Text(product.description!, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ProductDetailBottomActions extends StatelessWidget {
  final VoidCallback onAppro;
  final VoidCallback onSell;

  const ProductDetailBottomActions({
    super.key,
    required this.onAppro,
    required this.onSell,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Approvisionner'),
                onPressed: onAppro,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.shopping_cart_outlined, size: 18),
                label: const Text('Vendre'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                onPressed: onSell,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<bool?> showDeleteProductConfirmDialog(BuildContext context, Product product) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Supprimer le produit', style: TextStyle(fontWeight: FontWeight.w700)),
      content: Text('Voulez-vous vraiment supprimer "${product.name}" ? Cette action est irréversible.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Supprimer'),
        ),
      ],
    ),
  );
}
