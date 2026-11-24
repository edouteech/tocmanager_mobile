import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../models/vente.dart';
import '../../providers/product_provider.dart';
import '../../theme/app_theme.dart';
import 'vente_filter_helpers.dart';
import 'vente_form_pricing_helper.dart';

class VenteFormCartList extends StatelessWidget {
  final List<VenteItem> saleItems;
  final NumberFormat formatter;
  final double totalAmount;
  final void Function(int index, VenteItem item, Product? prod, ProductProvider provider) onEditUnitPrice;
  final ValueChanged<int> onDecrement;
  final void Function(int index, ProductProvider provider) onIncrement;
  final ValueChanged<int> onRemove;
  final void Function(int index, double newPrice) onSelectTierPrice;

  const VenteFormCartList({
    super.key,
    required this.saleItems,
    required this.formatter,
    required this.totalAmount,
    required this.onEditUnitPrice,
    required this.onDecrement,
    required this.onIncrement,
    required this.onRemove,
    required this.onSelectTierPrice,
  });

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final products = productProvider.products;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Panier (${saleItems.length})',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark),
              ),
              Text(
                formatter.format(totalAmount),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primary),
              ),
            ],
          ),
          if (saleItems.isEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Aucun article ajouté pour le moment.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textLight),
            ),
          ] else ...[
            const SizedBox(height: 10),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: saleItems.length,
              separatorBuilder: (_, __) => const Divider(height: 14),
              itemBuilder: (_, idx) {
                final item = saleItems[idx];
                final prod = products.where((p) => p.id == item.productId).firstOrNull;
                return _buildCartRow(idx, item, prod, productProvider);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCartRow(int idx, VenteItem item, Product? prod, ProductProvider productProvider) {
    final hasTiers = prod != null && (prod.priceSemiWholesale > 0 || prod.priceWholesale > 0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark),
                  ),
                  const SizedBox(height: 2),
                  InkWell(
                    onTap: () => onEditUnitPrice(idx, item, prod, productProvider),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${formatter.format(item.unitPrice)} / u',
                          style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.edit_outlined, size: 12, color: AppColors.primary),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, size: 20, color: AppColors.textMedium),
                  onPressed: () => onDecrement(idx),
                  visualDensity: VisualDensity.compact,
                ),
                Text(
                  formatVenteQty(item.quantity),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, size: 20, color: AppColors.primary),
                  onPressed: () => onIncrement(idx, productProvider),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(width: 4),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatter.format(item.total),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textDark),
                ),
                InkWell(
                  onTap: () => onRemove(idx),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 2),
                    child: Text('Retirer', style: TextStyle(fontSize: 10, color: AppColors.danger)),
                  ),
                ),
              ],
            ),
          ],
        ),
        if (hasTiers) ...[
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              buildVentePriceTierChip(
                label: 'Détail: ${prod.price.toStringAsFixed(0)}',
                isSelected: (item.unitPrice - prod.price).abs() < 0.01,
                onTap: () => onSelectTierPrice(idx, prod.price),
              ),
              if (prod.priceSemiWholesale > 0)
                buildVentePriceTierChip(
                  label: 'Demi-gros: ${prod.priceSemiWholesale.toStringAsFixed(0)}',
                  isSelected: (item.unitPrice - prod.priceSemiWholesale).abs() < 0.01,
                  onTap: () => onSelectTierPrice(idx, prod.priceSemiWholesale),
                ),
              if (prod.priceWholesale > 0)
                buildVentePriceTierChip(
                  label: 'Gros: ${prod.priceWholesale.toStringAsFixed(0)}',
                  isSelected: (item.unitPrice - prod.priceWholesale).abs() < 0.01,
                  onTap: () => onSelectTierPrice(idx, prod.priceWholesale),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
