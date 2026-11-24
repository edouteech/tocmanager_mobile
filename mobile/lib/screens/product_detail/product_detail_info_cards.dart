import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../providers/supplier_provider.dart';
import '../../theme/app_theme.dart';

class ProductStockCard extends StatelessWidget {
  final Product product;
  final NumberFormat formatter;

  const ProductStockCard({super.key, required this.product, required this.formatter});

  @override
  Widget build(BuildContext context) {
    final ratio = product.alertQuantity > 0
        ? (product.quantity / (product.alertQuantity * 3)).clamp(0.0, 1.0)
        : 1.0;
    final stockColor = product.isLowStock ? AppColors.danger : AppColors.success;

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Niveau de stock',
                style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w700, fontSize: 14),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: stockColor.withAlpha(25), borderRadius: BorderRadius.circular(20)),
                child: Text(
                  product.isLowStock ? 'Stock faible' : 'En stock',
                  style: TextStyle(color: stockColor, fontWeight: FontWeight.w600, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                '${product.quantity.toStringAsFixed(product.quantity.truncateToDouble() == product.quantity ? 0 : 1)} ${product.unit}',
                style: TextStyle(color: stockColor, fontSize: 24, fontWeight: FontWeight.w800),
              ),
              const SizedBox(width: 8),
              Text(
                '/ seuil ${product.alertQuantity.toStringAsFixed(0)}',
                style: const TextStyle(color: AppColors.textLight, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: ratio,
              backgroundColor: AppColors.divider,
              valueColor: AlwaysStoppedAnimation(stockColor),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Coût total : ${formatter.format(product.stockCost)}',
                style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
              Text(
                'Valeur vente : ${formatter.format(product.stockSaleValue)}',
                style: const TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ProductSupplierCard extends StatelessWidget {
  final int? supplierId;

  const ProductSupplierCard({super.key, required this.supplierId});

  @override
  Widget build(BuildContext context) {
    if (supplierId == null) return const SizedBox.shrink();

    return Consumer<SupplierProvider>(
      builder: (context, suppProvider, _) {
        final supplier = suppProvider.suppliers.where((s) => s.id == supplierId).firstOrNull;
        if (supplier == null) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.only(top: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.business_outlined, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fournisseur : ${supplier.name}',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textDark),
                    ),
                    if (supplier.phone != null && supplier.phone!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text('Tél : ${supplier.phone}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textMedium)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
