import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../providers/product_provider.dart';
import '../../theme/app_theme.dart';

class ProductBulkBar extends StatelessWidget {
  final int count;
  final VoidCallback onExport;
  final VoidCallback onDelete;
  final VoidCallback onClear;

  const ProductBulkBar({
    super.key,
    required this.count,
    required this.onExport,
    required this.onDelete,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppColors.primary,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: Colors.white.withAlpha(35), borderRadius: BorderRadius.circular(20)),
            child: Text(
              '$count sélectionné${count > 1 ? 's' : ''}',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          const Spacer(),
          _bulkBtn(Icons.download_outlined, 'Exporter', onExport),
          const SizedBox(width: 8),
          _bulkBtn(Icons.delete_outline, 'Supprimer', onDelete),
          const SizedBox(width: 4),
          IconButton(
            onPressed: onClear,
            icon: const Icon(Icons.close, color: Colors.white, size: 18),
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  Widget _bulkBtn(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(35),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withAlpha(60)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 14),
            const SizedBox(width: 5),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

void showConfirmDeleteProductModal(BuildContext context, Product product, ProductProvider provider) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Supprimer', style: TextStyle(fontWeight: FontWeight.w700)),
      content: Text('Supprimer "${product.name}" ?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
        ElevatedButton(
          onPressed: () async {
            await provider.delete(product.id!);
            if (ctx.mounted) Navigator.pop(ctx);
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
          child: const Text('Supprimer'),
        ),
      ],
    ),
  );
}

void showDeleteSelectedProductsDialog(
  BuildContext context,
  Set<int> selectedIds,
  VoidCallback onCleared,
) {
  final count = selectedIds.length;
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Supprimer la sélection', style: TextStyle(fontWeight: FontWeight.w700)),
      content: Text('Supprimer $count produit${count > 1 ? 's' : ''} sélectionné${count > 1 ? 's' : ''} ?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(ctx);
            final provider = context.read<ProductProvider>();
            for (final id in selectedIds.toList()) {
              await provider.delete(id);
            }
            onCleared();
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
          child: const Text('Supprimer'),
        ),
      ],
    ),
  );
}
