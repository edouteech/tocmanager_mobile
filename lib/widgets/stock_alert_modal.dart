import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/product_provider.dart';
import '../theme/app_theme.dart';
import '../screens/product_detail_screen.dart';

class StockAlertModal extends StatelessWidget {
  const StockAlertModal({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const StockAlertModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductProvider>(
      builder: (context, provider, _) {
        final alertProducts = provider.products
            .where((p) => p.isLowStock)
            .toList();

        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withAlpha(40),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.notifications_active_outlined,
                      color: AppColors.warning,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Alertes de Stock',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark,
                          ),
                        ),
                        Text(
                          '${alertProducts.length} produit(s) nécessitent un réapprovisionnement',
                          style: const TextStyle(
                            color: AppColors.textMedium,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: AppColors.textMedium),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),

              if (alertProducts.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.check_circle_outline_rounded,
                          size: 48,
                          color: AppColors.success,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Tous les stocks sont à niveau !',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Aucun produit en rupture ou stock faible.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: alertProducts.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (ctx, i) {
                      final p = alertProducts[i];
                      final isOut = p.quantity <= 0;

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isOut
                              ? AppColors.dangerLight
                              : AppColors.warning.withAlpha(20),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isOut
                                ? AppColors.danger.withAlpha(80)
                                : AppColors.warning.withAlpha(80),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: isOut
                                    ? AppColors.danger
                                    : AppColors.warning,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                isOut
                                    ? Icons.remove_shopping_cart_outlined
                                    : Icons.warning_amber_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isOut
                                        ? 'Rupture de stock !'
                                        : 'Stock actuel : ${p.quantity.toStringAsFixed(0)} / Seuil : ${p.alertQuantity.toStringAsFixed(0)} ${p.unit}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isOut
                                          ? AppColors.danger
                                          : AppColors.warning,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _showQuickApproModal(context, p, provider);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                              ),
                              child: const Text(
                                '+ Appro',
                                style: TextStyle(fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showQuickApproModal(
    BuildContext context,
    Product product,
    ProductProvider productProvider,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(product: product),
      ),
    );
  }
}
