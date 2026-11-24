import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/settings_provider.dart';
import '../../theme/app_theme.dart';

class ProductStatsBar extends StatelessWidget {
  final String? filterStatut;
  final ValueChanged<String?> onSelectStatut;

  const ProductStatsBar({
    super.key,
    required this.filterStatut,
    required this.onSelectStatut,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'fr_FR', symbol: 'F', decimalDigits: 0);

    return Consumer<ProductProvider>(
      builder: (context, provider, _) {
        final total = provider.products.length;
        final rupture = provider.products.where((p) => p.quantity == 0).length;
        final lowStock = provider.products.where((p) => p.isLowStock && p.quantity > 0).length;
        final featureEnabled = context.watch<SettingsProvider>().settings.enableAverageCostPrice;
        final totalSaleValue = provider.products.fold<double>(0, (sum, p) => sum + p.stockSaleValue);
        final totalCostValue =
            provider.products.fold<double>(0, (sum, p) => sum + p.stockCostWithFeature(featureEnabled));

        return Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Column(
            children: [
              Row(
                children: [
                  _statChip(
                    'Total ($total)',
                    filterStatut == null ? 'Tous' : 'Filtrer',
                    AppColors.primary,
                    isSelected: filterStatut == null,
                    onTap: () => onSelectStatut(null),
                  ),
                  const SizedBox(width: 6),
                  _statChip(
                    'Stock faible',
                    '$lowStock',
                    AppColors.warning,
                    isSelected: filterStatut == 'faible',
                    onTap: () => onSelectStatut(filterStatut == 'faible' ? null : 'faible'),
                  ),
                  const SizedBox(width: 6),
                  _statChip(
                    'Rupture',
                    '$rupture',
                    AppColors.danger,
                    isSelected: filterStatut == 'rupture',
                    onTap: () => onSelectStatut(filterStatut == 'rupture' ? null : 'rupture'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _valuationBox(
                    icon: Icons.shopping_bag_outlined,
                    label: 'Coût stock (achat)',
                    value: formatter.format(totalCostValue),
                    color: AppColors.primary,
                    bg: AppColors.primaryLight,
                  ),
                  const SizedBox(width: 8),
                  _valuationBox(
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'Valeur stock (vente)',
                    value: formatter.format(totalSaleValue),
                    color: AppColors.success,
                    bg: AppColors.successLight,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _valuationBox({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required Color bg,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withAlpha(40)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textMedium),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              value,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _statChip(
    String label,
    String value,
    Color color, {
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color : color.withAlpha(15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isSelected ? color : color.withAlpha(40)),
          ),
          child: Column(
            children: [
              Text(
                value,
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: isSelected ? Colors.white : color),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                  color: isSelected ? Colors.white.withAlpha(230) : AppColors.textMedium,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
