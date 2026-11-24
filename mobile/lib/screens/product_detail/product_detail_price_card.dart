import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../providers/settings_provider.dart';
import '../../theme/app_theme.dart';

class ProductPriceCard extends StatelessWidget {
  final Product product;
  final NumberFormat formatter;

  const ProductPriceCard({super.key, required this.product, required this.formatter});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>().settings;
    final featureEnabled = settings.enableAverageCostPrice;
    final hasAverageCost =
        featureEnabled && product.averageCostPrice != null && product.averageCostPrice! > 0;
    final effectiveCost = product.effectiveCostPrice(featureEnabled);

    final margin = product.price - effectiveCost;
    final marginPct = effectiveCost > 0 ? (margin / effectiveCost * 100) : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Grilles Tarifaires',
            style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w700, fontSize: 14),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _priceItem(label: 'Prix Détail', value: formatter.format(product.price), color: AppColors.primary),
              ),
              Expanded(
                child: hasAverageCost
                    ? _priceItem(
                        label: 'Prix Moyen',
                        value: formatter.format(product.averageCostPrice!),
                        color: AppColors.textMedium,
                        subText: 'Init: ${formatter.format(product.costPrice)}',
                        subTextColor: AppColors.textLight,
                      )
                    : _priceItem(
                        label: "Prix d'achat",
                        value: formatter.format(product.costPrice),
                        color: AppColors.textMedium,
                      ),
              ),
              Expanded(
                child: _priceItem(
                  label: 'Marge',
                  value: '${formatter.format(margin)} (${marginPct.toStringAsFixed(0)}%)',
                  color: margin >= 0 ? AppColors.success : AppColors.danger,
                  smallText: true,
                ),
              ),
            ],
          ),
          if (product.priceSemiWholesale > 0 || product.priceWholesale > 0) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1, color: AppColors.divider),
            ),
            Row(
              children: [
                if (product.priceSemiWholesale > 0)
                  Expanded(
                    child: _priceItem(
                      label: 'Prix Demi-Gros',
                      value: formatter.format(product.priceSemiWholesale),
                      color: AppColors.purple,
                      subText: product.minQtySemiWholesale > 0
                          ? 'Dès ${product.minQtySemiWholesale.toStringAsFixed(0)} ${product.unit}'
                          : null,
                    ),
                  ),
                if (product.priceWholesale > 0)
                  Expanded(
                    child: _priceItem(
                      label: 'Prix Grossiste',
                      value: formatter.format(product.priceWholesale),
                      color: AppColors.success,
                      subText: product.minQtyWholesale > 0
                          ? 'Dès ${product.minQtyWholesale.toStringAsFixed(0)} ${product.unit}'
                          : null,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _priceItem({
    required String label,
    required String value,
    required Color color,
    bool smallText = false,
    String? subText,
    Color? subTextColor,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(color: color, fontSize: smallText ? 11 : 16, fontWeight: FontWeight.w700),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: AppColors.textLight, fontSize: 11)),
        if (subText != null) ...[
          const SizedBox(height: 2),
          Text(
            subText,
            style: TextStyle(color: subTextColor ?? color, fontSize: 10, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}
