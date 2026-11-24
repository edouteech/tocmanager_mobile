import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';

class HomeStatsGrid extends StatelessWidget {
  final Map<String, dynamic> stats;
  final NumberFormat formatter;
  final void Function(int, {String? statusFilter})? onNav;

  const HomeStatsGrid({
    super.key,
    required this.stats,
    required this.formatter,
    this.onNav,
  });

  @override
  Widget build(BuildContext context) {
    final stockValue = (stats['stockValue'] ?? 0.0) as double;
    final stockCost = (stats['stockCost'] ?? 0.0) as double;
    final items = [
      _StatData(
        label: 'Produits',
        value: '${stats['productCount'] ?? 0}',
        icon: Icons.inventory_2_outlined,
        color: AppColors.primary,
        bgColor: AppColors.primaryLight,
      ),
      _StatData(
        label: 'Catégories',
        value: '${stats['categoryCount'] ?? 0}',
        icon: Icons.category_outlined,
        color: AppColors.success,
        bgColor: AppColors.successLight,
      ),
      _StatData(
        label: 'Valeur stock (vente)',
        value: formatter.format(stockValue),
        subValue: 'Coût : ${formatter.format(stockCost)}',
        icon: Icons.show_chart,
        color: AppColors.purple,
        bgColor: AppColors.purpleLight,
        smallText: true,
      ),
      _StatData(
        label: 'Alertes stock',
        value: '${stats['lowStockCount'] ?? 0}',
        icon: Icons.warning_amber_outlined,
        color: AppColors.danger,
        bgColor: AppColors.dangerLight,
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.38,
      children: items.map(_buildStatCard).toList(),
    );
  }

  Widget _buildStatCard(_StatData data) {
    return InkWell(
      onTap: () {
        if (onNav != null) {
          if (data.label == 'Produits' || data.label.startsWith('Valeur stock')) onNav!(1);
          if (data.label == 'Catégories') onNav!(2);
          if (data.label == 'Alertes stock') onNav!(1, statusFilter: 'lowStock');
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(color: data.bgColor, borderRadius: BorderRadius.circular(10)),
              child: Icon(data.icon, color: data.color, size: 18),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.value,
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontSize: data.smallText ? 12 : 20,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (data.subValue != null)
                  Text(
                    data.subValue!,
                    style: const TextStyle(color: AppColors.textMedium, fontSize: 10, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                Text(data.label, style: const TextStyle(color: AppColors.textLight, fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class HomeAlertCard extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const HomeAlertCard({super.key, required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.dangerLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.danger.withAlpha(50)),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Alerte stock',
                    style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  Text(
                    '$count produit${count > 1 ? 's' : ''} en stock faible ou rupture',
                    style: const TextStyle(color: AppColors.textMedium, fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textLight),
          ],
        ),
      ),
    );
  }
}

class _StatData {
  final String label;
  final String value;
  final String? subValue;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final bool smallText;

  const _StatData({
    required this.label,
    required this.value,
    this.subValue,
    required this.icon,
    required this.color,
    required this.bgColor,
    this.smallText = false,
  });
}
