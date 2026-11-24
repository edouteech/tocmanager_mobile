import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/decaissement.dart';
import '../providers/decaissement_provider.dart';
import '../providers/settings_provider.dart';
import '../services/decaissement_export_service.dart';
import '../theme/app_theme.dart';
import 'decaissements/decaissement_data_table.dart';
import 'decaissements/decaissement_detail_sheet.dart';
import 'decaissements/decaissement_filter_helpers.dart';
import 'decaissements/decaissement_filters_and_summary.dart';
import 'decaissements/decaissement_form_modal.dart';
import 'decaissements/decaissement_mobile_list.dart';

class DecaissementScreen extends StatefulWidget {
  const DecaissementScreen({super.key});

  @override
  State<DecaissementScreen> createState() => _DecaissementScreenState();
}

class _DecaissementScreenState extends State<DecaissementScreen> {
  String _search = '';
  String? _filterCategory;
  String _filterPeriod = 'all'; // 'all', 'today', 'yesterday', 'month'
  String _sortBy = 'recent'; // 'recent', 'amount_desc', 'category_asc'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DecaissementProvider>().load();
    });
  }

  List<Decaissement> _filtered(List<Decaissement> allItems) => filterAndSortDecaissements(
        allItems,
        filterCategory: _filterCategory,
        filterPeriod: _filterPeriod,
        search: _search,
        sortBy: _sortBy,
      );

  void _showForm(BuildContext context, {Decaissement? decaissement}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => DecaissementFormModal(
        decaissement: decaissement,
        onSave: (dec) async {
          final provider = context.read<DecaissementProvider>();
          if (decaissement == null) {
            await provider.add(dec);
          } else {
            await provider.update(dec);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'fr_FR', symbol: 'F', decimalDigits: 0);
    final isLargeScreen = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Dépenses / Décaissements', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Exporter les dépenses',
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppColors.danger.withAlpha(20), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.ios_share_outlined, color: AppColors.danger, size: 20),
            ),
            onSelected: (val) {
              final settings = context.read<SettingsProvider>().settings;
              final items = _filtered(context.read<DecaissementProvider>().items);
              final periodName = decaissementPeriodLabel(_filterPeriod);
              if (val == 'excel') {
                DecaissementExportService.exportDecaissementsExcel(context, items, periodName);
              } else if (val == 'pdf') {
                DecaissementExportService.exportDecaissementsPdfReport(context, items, periodName, settings);
              }
            },
            itemBuilder: (ctx) => const [
              PopupMenuItem(
                value: 'excel',
                child: Row(
                  children: [
                    Icon(Icons.table_chart_outlined, size: 18, color: AppColors.success),
                    SizedBox(width: 8),
                    Text('Exporter Excel (.xlsx)'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'pdf',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf_outlined, size: 18, color: AppColors.danger),
                    SizedBox(width: 8),
                    Text('Rapport PDF (A4)'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: () => _showForm(context),
            icon: const Icon(Icons.add, color: AppColors.danger),
            tooltip: 'Nouvelle dépense',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Consumer<DecaissementProvider>(
        builder: (context, provider, _) {
          final filtered = _filtered(provider.items);
          final now = DateTime.now();
          final totalMonth = provider.items
              .where((d) => d.date.year == now.year && d.date.month == now.month)
              .fold(0.0, (sum, d) => sum + d.amount);
          final totalFiltered = filtered.fold(0.0, (sum, d) => sum + d.amount);

          return Column(
            children: [
              DecaissementSummaryBar(
                totalMonth: totalMonth,
                filteredCount: filtered.length,
                totalFiltered: totalFiltered,
                formatter: formatter,
              ),
              DecaissementSearchAndSortBar(
                onSearchChanged: (v) => setState(() => _search = v),
                onSortSelected: (val) => setState(() => _sortBy = val),
              ),
              DecaissementPeriodAndCategoryFilters(
                filterPeriod: _filterPeriod,
                filterCategory: _filterCategory,
                onPeriodChanged: (type) => setState(() => _filterPeriod = type),
                onCategoryChanged: (cat) => setState(() => _filterCategory = cat),
              ),
              Expanded(
                child: provider.loading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                    : filtered.isEmpty
                        ? const DecaissementEmptyState()
                        : !isLargeScreen
                            ? DecaissementMobileListView(
                                items: filtered,
                                formatter: formatter,
                                onTapItem: (d) => showDecaissementDetailModal(
                                  context,
                                  d,
                                  formatter,
                                  onDelete: () => showDeleteDecaissementDialog(context, d, provider),
                                  onEdit: () => _showForm(context, decaissement: d),
                                ),
                              )
                            : SingleChildScrollView(
                                padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: AppColors.divider),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withAlpha(5),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: DecaissementDataTable(
                                        items: filtered,
                                        formatter: formatter,
                                        onEdit: (d) => _showForm(context, decaissement: d),
                                        onDelete: (d) => showDeleteDecaissementDialog(context, d, provider),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () => _showForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Nouveau décaissement'),
        backgroundColor: AppColors.danger,
      ),
    );
  }
}
