import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:excel/excel.dart' as xl;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import '../providers/product_provider.dart';
import '../providers/vente_provider.dart';
import '../providers/decaissement_provider.dart';
import '../theme/app_theme.dart';
import '../models/vente.dart';
import '../models/decaissement.dart';
import '../models/product.dart';

enum ReportPeriod { today, last7days, thisMonth, thisYear, allTime }

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  ReportPeriod _period = ReportPeriod.thisMonth;

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'fr_FR', symbol: 'F', decimalDigits: 0);

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
              if (val == 'pdf') _exportReportPdf(context);
              if (val == 'excel') _exportReportExcel(context);
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'pdf', child: Row(children: [Icon(Icons.picture_as_pdf, color: AppColors.danger, size: 18), SizedBox(width: 8), Text('Export PDF')])),
              const PopupMenuItem(value: 'excel', child: Row(children: [Icon(Icons.table_chart, color: AppColors.success, size: 18), SizedBox(width: 8), Text('Export Excel')])),
            ],
          ),
        ],
      ),
      body: Consumer3<VenteProvider, DecaissementProvider, ProductProvider>(
        builder: (context, venteProv, decaissementProv, productProv, _) {
          final now = DateTime.now();

          // Filter Sales & Expenses by selected period
          final filteredVentes = venteProv.items.where((v) => _matchPeriod(v.date, now)).toList();
          final filteredDecaissements = decaissementProv.items.where((d) => _matchPeriod(d.date, now)).toList();

          // Financial metrics
          final double ca = filteredVentes.fold(0.0, (sum, v) => sum + v.totalAmount);
          final double totalExpenses = filteredDecaissements.fold(0.0, (sum, d) => sum + d.amount);

          // Cost price calculation for margin
          double cogs = 0.0;
          for (final v in filteredVentes) {
            for (final item in v.items) {
              final p = productProv.products.where((p) => p.id == item.productId).firstOrNull;
              cogs += (p?.costPrice ?? 0) * item.quantity;
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
                _buildPeriodFilter(),
                const SizedBox(height: 16),
                _buildKpiGrid(ca, margeBrute, tauxMarge, totalExpenses, tresorerieNette, formatter),
                const SizedBox(height: 20),
                _buildSectionHeader(Icons.bar_chart_rounded, 'Ventes vs Dépenses (Marge)'),
                const SizedBox(height: 10),
                _buildBarChartCard(ca, totalExpenses, margeBrute, formatter),
                const SizedBox(height: 20),
                _buildSectionHeader(Icons.pie_chart_outline_rounded, 'Répartition des Dépenses par Catégorie'),
                const SizedBox(height: 10),
                _buildExpenseCategoryChart(filteredDecaissements, formatter),
                const SizedBox(height: 20),
                _buildSectionHeader(Icons.workspace_premium_rounded, 'Top Produits les plus vendus'),
                const SizedBox(height: 10),
                _buildTopProductsList(filteredVentes, productProv.products, formatter),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  bool _matchPeriod(DateTime date, DateTime now) {
    switch (_period) {
      case ReportPeriod.today:
        return date.year == now.year && date.month == now.month && date.day == now.day;
      case ReportPeriod.last7days:
        return date.isAfter(now.subtract(const Duration(days: 7)));
      case ReportPeriod.thisMonth:
        return date.year == now.year && date.month == now.month;
      case ReportPeriod.thisYear:
        return date.year == now.year;
      case ReportPeriod.allTime:
        return true;
    }
  }

  Widget _buildPeriodFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _periodChip('Aujourd\'hui', ReportPeriod.today),
          const SizedBox(width: 8),
          _periodChip('7 derniers jours', ReportPeriod.last7days),
          const SizedBox(width: 8),
          _periodChip('Ce mois-ci', ReportPeriod.thisMonth),
          const SizedBox(width: 8),
          _periodChip('Cette année', ReportPeriod.thisYear),
          const SizedBox(width: 8),
          _periodChip('Tout l\'historique', ReportPeriod.allTime),
        ],
      ),
    );
  }

  Widget _periodChip(String label, ReportPeriod period) {
    final selected = _period == period;
    return ChoiceChip(
      label: Text(label, style: TextStyle(color: selected ? Colors.white : AppColors.textDark, fontWeight: selected ? FontWeight.w700 : FontWeight.w500, fontSize: 12)),
      selected: selected,
      selectedColor: AppColors.primary,
      backgroundColor: Colors.white,
      onSelected: (_) => setState(() => _period = period),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textDark),
        ),
      ],
    );
  }

  Widget _buildKpiGrid(double ca, double marge, double tauxMarge, double depenses, double tresorerie, NumberFormat formatter) {
    return Column(
      children: [
        Row(
          children: [
            _kpiCard('Chiffre d\'Affaires', formatter.format(ca), Icons.trending_up, AppColors.success, sub: 'Recettes des ventes'),
            const SizedBox(width: 10),
            _kpiCard('Marge Brute', formatter.format(marge), Icons.pie_chart_outline, AppColors.primary, sub: '${tauxMarge.toStringAsFixed(1)}% du CA'),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _kpiCard('Total Dépenses', formatter.format(depenses), Icons.trending_down, AppColors.danger, sub: 'Décaissements'),
            const SizedBox(width: 10),
            _kpiCard('Trésorerie Nette', formatter.format(tresorerie), Icons.account_balance_wallet_outlined, tresorerie >= 0 ? AppColors.success : AppColors.danger, sub: 'CA - Dépenses'),
          ],
        ),
      ],
    );
  }

  Widget _kpiCard(String title, String value, IconData icon, Color color, {String? sub}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                Expanded(child: Text(title, style: const TextStyle(fontSize: 11, color: AppColors.textMedium, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
              ],
            ),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color), maxLines: 1, overflow: TextOverflow.ellipsis),
            if (sub != null) ...[
              const SizedBox(height: 2),
              Text(sub, style: const TextStyle(fontSize: 10, color: AppColors.textLight)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBarChartCard(double ca, double depenses, double marge, NumberFormat formatter) {
    final double maxVal = (max(ca, max(depenses, marge > 0 ? marge : 0.0)) as num).toDouble().clamp(1.0, double.infinity);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          _barRow('CA (Ventes)', ca, maxVal, AppColors.success, formatter),
          const SizedBox(height: 12),
          _barRow('Dépenses', depenses, maxVal, AppColors.danger, formatter),
          const SizedBox(height: 12),
          _barRow('Marge Brute', marge > 0 ? marge : 0.0, maxVal, AppColors.primary, formatter),
        ],
      ),
    );
  }

  Widget _barRow(String label, double val, double maxVal, Color color, NumberFormat formatter) {
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

  Widget _buildExpenseCategoryChart(List<Decaissement> decaissements, NumberFormat formatter) {
    if (decaissements.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.divider)),
        child: const Center(child: Text('Aucune dépense enregistrée sur cette période.', style: TextStyle(color: AppColors.textLight, fontSize: 13))),
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

  Widget _buildTopProductsList(List<Vente> ventes, List<Product> products, NumberFormat formatter) {
    if (ventes.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.divider)),
        child: const Center(child: Text('Aucune vente enregistrée sur cette période.', style: TextStyle(color: AppColors.textLight, fontSize: 13))),
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
              child: Text('$rank', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: rank == 1 ? Colors.white : AppColors.primary)),
            ),
            title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            subtitle: Text('Quantité vendue: ${qty.toStringAsFixed(0)} ${p?.unit ?? "pce"}', style: const TextStyle(fontSize: 11, color: AppColors.textMedium)),
            trailing: Text(formatter.format(revenue), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.primary)),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _exportReportPdf(BuildContext context) async {
    try {
      final doc = pw.Document();
      final numFmt = NumberFormat('#,##0', 'fr_FR');
      final dateFmt = DateFormat('dd/MM/yyyy HH:mm');

      final venteProv = context.read<VenteProvider>();
      final decaissementProv = context.read<DecaissementProvider>();
      final now = DateTime.now();

      final ventes = venteProv.items.where((v) => _matchPeriod(v.date, now)).toList();
      final decaissements = decaissementProv.items.where((d) => _matchPeriod(d.date, now)).toList();

      final ca = ventes.fold(0.0, (sum, v) => sum + v.totalAmount);
      final depenses = decaissements.fold(0.0, (sum, d) => sum + d.amount);
      final net = ca - depenses;

      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context ctx) {
            return pw.Padding(
              padding: const pw.EdgeInsets.all(24),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Rapport Financier Synthétique', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Généré le ${dateFmt.format(now)}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                  pw.Divider(),
                  pw.SizedBox(height: 14),
                  pw.Text('Résumé des opérations :', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 8),
                  pw.Bullet(text: 'Chiffre d\'Affaires (Ventes) : ${numFmt.format(ca)} FCFA'),
                  pw.Bullet(text: 'Total Décaissements (Dépenses) : ${numFmt.format(depenses)} FCFA'),
                  pw.Bullet(text: 'Résultat Net : ${numFmt.format(net)} FCFA'),
                ],
              ),
            );
          },
        ),
      );

      await Printing.sharePdf(bytes: await doc.save(), filename: 'rapport_financier_${DateFormat('yyyyMMdd').format(now)}.pdf');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur d\'export PDF: $e')));
      }
    }
  }

  Future<void> _exportReportExcel(BuildContext context) async {
    try {
      final excel = xl.Excel.createExcel();
      excel.rename('Sheet1', 'Rapport');
      final sheet = excel['Rapport'];

      final venteProv = context.read<VenteProvider>();
      final decaissementProv = context.read<DecaissementProvider>();
      final now = DateTime.now();

      final ventes = venteProv.items.where((v) => _matchPeriod(v.date, now)).toList();
      final decaissements = decaissementProv.items.where((d) => _matchPeriod(d.date, now)).toList();

      sheet.appendRow([xl.TextCellValue('Rapport Financier TocManager')]);
      sheet.appendRow([xl.TextCellValue('Période: ${DateFormat("dd/MM/yyyy").format(now)}')]);
      sheet.appendRow([]);
      sheet.appendRow([xl.TextCellValue('Indicateur'), xl.TextCellValue('Montant (FCFA)')]);

      final ca = ventes.fold(0.0, (sum, v) => sum + v.totalAmount);
      final depenses = decaissements.fold(0.0, (sum, d) => sum + d.amount);

      sheet.appendRow([xl.TextCellValue('Chiffre d\'Affaires'), xl.DoubleCellValue(ca)]);
      sheet.appendRow([xl.TextCellValue('Total Dépenses'), xl.DoubleCellValue(depenses)]);
      sheet.appendRow([xl.TextCellValue('Trésorerie Nette'), xl.DoubleCellValue(ca - depenses)]);

      final bytes = excel.encode();
      if (bytes != null) {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/rapport_${now.millisecondsSinceEpoch}.xlsx');
        await file.writeAsBytes(bytes);
        await Share.shareXFiles([XFile(file.path)], text: 'Rapport financier TocManager');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur d\'export Excel: $e')));
      }
    }
  }
}
