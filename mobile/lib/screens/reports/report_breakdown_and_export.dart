import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/decaissement.dart';
import '../../models/product.dart';
import '../../models/vente.dart';
import '../../theme/app_theme.dart';

class ReportBarChartCard extends StatelessWidget {
  final double ca;
  final double depenses;
  final double marge;
  final NumberFormat formatter;

  const ReportBarChartCard({
    super.key,
    required this.ca,
    required this.depenses,
    required this.marge,
    required this.formatter,
  });

  @override
  Widget build(BuildContext context) {
    final double maxVal =
        (max(ca, max(depenses, marge > 0 ? marge : 0.0)) as num).toDouble().clamp(1.0, double.infinity);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          _barRow('CA (Ventes)', ca, maxVal, AppColors.success),
          const SizedBox(height: 12),
          _barRow('Dépenses', depenses, maxVal, AppColors.danger),
          const SizedBox(height: 12),
          _barRow('Marge Brute', marge > 0 ? marge : 0.0, maxVal, AppColors.primary),
        ],
      ),
    );
  }

  Widget _barRow(String label, double val, double maxVal, Color color) {
    final pct = (val / maxVal).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark)),
            Text(formatter.format(val), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 12,
            backgroundColor: AppColors.background,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class ReportExpenseCategoryChart extends StatelessWidget {
  final List<Decaissement> decaissements;
  final NumberFormat formatter;

  const ReportExpenseCategoryChart({
    super.key,
    required this.decaissements,
    required this.formatter,
  });

  @override
  Widget build(BuildContext context) {
    if (decaissements.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: const Center(
          child: Text('Aucune dépense enregistrée sur cette période.',
              style: TextStyle(color: AppColors.textLight, fontSize: 13)),
        ),
      );
    }

    final Map<String, double> categoryTotals = {};
    for (final d in decaissements) {
      categoryTotals[d.category] = (categoryTotals[d.category] ?? 0.0) + d.amount;
    }

    final sortedEntries = categoryTotals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final double totalExpenses = decaissements.fold(0.0, (sum, d) => sum + d.amount);
    final colors = [
      AppColors.primary,
      AppColors.warning,
      AppColors.danger,
      AppColors.success,
      Colors.purple,
      Colors.teal,
      Colors.orange,
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: sortedEntries.asMap().entries.map((entry) {
          final idx = entry.key;
          final cat = entry.value.key;
          final amount = entry.value.value;
          final pct = totalExpenses > 0 ? (amount / totalExpenses * 100).toStringAsFixed(1) : '0';
          final color = colors[idx % colors.length];

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                const SizedBox(width: 10),
                Expanded(child: Text(cat, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                Text('$pct%  ', style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
                Text(formatter.format(amount), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class ReportTopProductsList extends StatelessWidget {
  final List<Vente> ventes;
  final List<Product> products;
  final NumberFormat formatter;

  const ReportTopProductsList({
    super.key,
    required this.ventes,
    required this.products,
    required this.formatter,
  });

  @override
  Widget build(BuildContext context) {
    if (ventes.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: const Center(
          child: Text('Aucune vente enregistrée sur cette période.',
              style: TextStyle(color: AppColors.textLight, fontSize: 13)),
        ),
      );
    }

    final Map<int, double> productQtyMap = {};
    final Map<int, double> productTotalMap = {};
    for (final v in ventes) {
      for (final item in v.items) {
        productQtyMap[item.productId] = (productQtyMap[item.productId] ?? 0.0) + item.quantity;
        productTotalMap[item.productId] = (productTotalMap[item.productId] ?? 0.0) + item.total;
      }
    }

    final sortedProductIds = productQtyMap.keys.toList()
      ..sort((a, b) => (productTotalMap[b] ?? 0.0).compareTo(productTotalMap[a] ?? 0.0));
    final topIds = sortedProductIds.take(5).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: topIds.asMap().entries.map((entry) {
          final rank = entry.key + 1;
          final pid = entry.value;
          final p = products.where((item) => item.id == pid).firstOrNull;
          final name = p?.name ?? 'Produit #$pid';
          final qty = productQtyMap[pid] ?? 0.0;
          final revenue = productTotalMap[pid] ?? 0.0;

          return ListTile(
            leading: CircleAvatar(
              radius: 14,
              backgroundColor: rank == 1 ? AppColors.warning : AppColors.primarySurface,
              child: Text(
                '$rank',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: rank == 1 ? Colors.white : AppColors.primary,
                ),
              ),
            ),
            title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            subtitle: Text('Quantité vendue: ${qty.toStringAsFixed(0)} ${p?.unit ?? "pce"}',
                style: const TextStyle(fontSize: 11, color: AppColors.textMedium)),
            trailing: Text(formatter.format(revenue),
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.primary)),
          );
        }).toList(),
      ),
    );
  }
}
