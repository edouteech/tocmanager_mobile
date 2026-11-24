import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../widgets/sync_status_badge.dart';

class VenteScreenHeader extends StatelessWidget {
  final VoidCallback onBack;
  final ValueChanged<String> onExportSelected;
  final VoidCallback onNewVente;

  const VenteScreenHeader({
    super.key,
    required this.onBack,
    required this.onExportSelected,
    required this.onNewVente,
  });

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 600;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 16, 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          if (Navigator.canPop(context))
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.textDark),
              onPressed: onBack,
              tooltip: 'Retour',
            )
          else
            const SizedBox(width: 4),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ventes & Caisse',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.textDark),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Encaissements, tickets & crédits clients',
                  style: TextStyle(fontSize: 11, color: AppColors.textMedium),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SyncStatusBadge(),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            tooltip: 'Exporter les ventes',
            onSelected: onExportSelected,
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.ios_share_outlined, color: AppColors.primary, size: 20),
            ),
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'excel',
                child: Row(
                  children: [
                    Icon(Icons.table_chart_outlined, size: 18, color: AppColors.success),
                    SizedBox(width: 10),
                    Text('Exporter en Excel (.xlsx)'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'pdf',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf_outlined, size: 18, color: AppColors.danger),
                    SizedBox(width: 10),
                    Text('Rapport PDF'),
                  ],
                ),
              ),
            ],
          ),
          if (isWide) ...[
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: onNewVente,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              icon: const Icon(Icons.add_shopping_cart, size: 18),
              label: const Text('Nouvelle vente'),
            ),
          ],
        ],
      ),
    );
  }
}

class VenteSummaryCards extends StatelessWidget {
  final int filteredCount;
  final double totalFilteredAmount;
  final double todaySalesAmount;
  final double totalSalesAmount;
  final bool isFiltered;
  final NumberFormat formatter;

  const VenteSummaryCards({
    super.key,
    required this.filteredCount,
    required this.totalFilteredAmount,
    required this.todaySalesAmount,
    required this.totalSalesAmount,
    required this.isFiltered,
    required this.formatter,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Row(
        children: [
          _buildKpiCard(
            label: isFiltered ? 'Ventes (filtre)' : 'Total ventes',
            value: '$filteredCount',
            color: AppColors.primary,
          ),
          const SizedBox(width: 8),
          _buildKpiCard(
            label: 'Aujourd\'hui',
            value: formatter.format(todaySalesAmount),
            color: AppColors.success,
          ),
          const SizedBox(width: 8),
          _buildKpiCard(
            label: isFiltered ? 'CA (filtre)' : 'Chiffre d\'aff.',
            value: formatter.format(isFiltered ? totalFilteredAmount : totalSalesAmount),
            color: AppColors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard({required String label, required String value, required Color color}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: color.withAlpha(18),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(50)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: AppColors.textMedium, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
