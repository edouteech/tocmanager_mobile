import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/category.dart';
import '../../theme/app_theme.dart';
import '../../utils/category_icon_helper.dart';

class CategoryDetailAppBar extends StatelessWidget {
  final Category category;
  final Color color;

  const CategoryDetailAppBar({super.key, required this.category, required this.color});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: color,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.withAlpha(220), color],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: Colors.white.withAlpha(50), shape: BoxShape.circle),
                    child: Icon(CategoryIconHelper.getIcon(category.icon), color: Colors.white, size: 32),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    category.name,
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
                  ),
                  if (category.description != null) ...[
                    const SizedBox(height: 4),
                    Text(category.description!, style: const TextStyle(color: Colors.white70, fontSize: 13)),
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

class CategoryDetailInfoCard extends StatelessWidget {
  final Color color;
  final NumberFormat formatter;
  final double stockCost;
  final double stockSaleValue;
  final int productCount;
  final int lowStockCount;

  const CategoryDetailInfoCard({
    super.key,
    required this.color,
    required this.formatter,
    required this.stockCost,
    required this.stockSaleValue,
    required this.productCount,
    required this.lowStockCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          _statItem(label: 'Produits', value: '$productCount', icon: Icons.inventory_2_outlined, color: color),
          _divider(),
          _statItem(label: 'Coût stock', value: formatter.format(stockCost), icon: Icons.shopping_bag_outlined, color: AppColors.primary, smallText: true),
          _divider(),
          _statItem(label: 'Valeur vente', value: formatter.format(stockSaleValue), icon: Icons.account_balance_wallet_outlined, color: AppColors.success, smallText: true),
          _divider(),
          _statItem(
            label: 'Alertes',
            value: '$lowStockCount',
            icon: Icons.warning_amber_outlined,
            color: lowStockCount > 0 ? AppColors.danger : AppColors.success,
          ),
        ],
      ),
    );
  }

  Widget _statItem({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    bool smallText = false,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(color: AppColors.textDark, fontSize: smallText ? 11 : 18, fontWeight: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(label, style: const TextStyle(color: AppColors.textLight, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _divider() => Container(width: 1, height: 48, color: AppColors.divider);
}
