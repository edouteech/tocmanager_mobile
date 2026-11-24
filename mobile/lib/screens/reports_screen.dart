import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/date_filter_period.dart';
import '../providers/decaissement_provider.dart';
import '../providers/product_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/vente_provider.dart';
import '../theme/app_theme.dart';
import 'reports/report_breakdown_and_export.dart';
import 'reports/report_export_service.dart';
import 'reports/report_widgets.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateFilterPeriod _period = DateFilterPeriod.thisMonth();

  @override
  Widget build(BuildContext context) {
    final currencyCode = context.watch<SettingsProvider>().settings.currency;
    final formatter = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: reportCurrencySymbol(currencyCode),
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Analytique & Rapports', style: TextStyle(fontWeight: FontWeight.w700)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.picture_as_pdf_outlined, color: AppColors.primary),
            tooltip: 'Exporter Bilan',
            onSelected: (val) {
              if (val == 'pdf') ReportExportService.exportPdf(context, _period);
              if (val == 'excel') ReportExportService.exportExcel(context, _period);
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'pdf',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf, color: AppColors.danger, size: 18),
                    SizedBox(width: 8),
                    Text('Export PDF'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'excel',
                child: Row(
                  children: [
                    Icon(Icons.table_chart, color: AppColors.success, size: 18),
                    SizedBox(width: 8),
                    Text('Export Excel'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer3<VenteProvider, DecaissementProvider, ProductProvider>(
        builder: (context, venteProv, decaissementProv, productProv, _) {
          final filteredVentes = venteProv.items.where((v) => _period.matches(v.date)).toList();
          final filteredDecaissements = decaissementProv.items.where((d) => _period.matches(d.date)).toList();

          final double ca = filteredVentes.fold(0.0, (sum, v) => sum + v.totalAmount);
          final double totalExpenses = filteredDecaissements.fold(0.0, (sum, d) => sum + d.amount);
          final featureEnabled = context.watch<SettingsProvider>().settings.enableAverageCostPrice;
          double cogs = 0.0;
          for (final v in filteredVentes) {
            for (final item in v.items) {
              final p = productProv.products.where((p) => p.id == item.productId).firstOrNull;
              final itemCost = item.costPrice;
              final unitCost = (itemCost != null && itemCost > 0)
                  ? itemCost
                  : (p?.effectiveCostPrice(featureEnabled) ?? 0.0);
              cogs += unitCost * item.quantity;
            }
          }

          final double margeBrute = ca - cogs;
          final double tauxMarge = ca > 0 ? (margeBrute / ca) * 100 : 0.0;
          final double tresorerieNette = ca - totalExpenses;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ReportPeriodFilterBar(
                  period: _period,
                  onChanged: (next) => setState(() => _period = next),
                ),
                const SizedBox(height: 16),
                ReportKpiGrid(
                  ca: ca,
                  marge: margeBrute,
                  tauxMarge: tauxMarge,
                  depenses: totalExpenses,
                  tresorerie: tresorerieNette,
                  formatter: formatter,
                ),
                const SizedBox(height: 20),
                buildReportSectionHeader(Icons.bar_chart_rounded, 'Ventes vs Dépenses (Marge)'),
                const SizedBox(height: 10),
                ReportBarChartCard(
                  ca: ca,
                  depenses: totalExpenses,
                  marge: margeBrute,
                  formatter: formatter,
                ),
                const SizedBox(height: 20),
                buildReportSectionHeader(Icons.pie_chart_outline_rounded, 'Répartition des Dépenses par Catégorie'),
                const SizedBox(height: 10),
                ReportExpenseCategoryChart(decaissements: filteredDecaissements, formatter: formatter),
                const SizedBox(height: 20),
                buildReportSectionHeader(Icons.workspace_premium_rounded, 'Top Produits les plus vendus'),
                const SizedBox(height: 10),
                ReportTopProductsList(
                  ventes: filteredVentes,
                  products: productProv.products,
                  formatter: formatter,
                ),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }
}
