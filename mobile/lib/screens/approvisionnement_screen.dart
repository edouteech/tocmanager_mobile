import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/approvisionnement.dart';
import '../providers/approvisionnement_provider.dart';
import '../providers/product_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/supplier_provider.dart';
import '../providers/tenant_provider.dart';
import '../services/approvisionnement_export_service.dart';
import '../theme/app_theme.dart';
import '../widgets/select_operational_magasin_modal.dart';
import 'approvisionnements/approvisionnement_data_table.dart';
import 'approvisionnements/approvisionnement_detail_sheet.dart';
import 'approvisionnements/approvisionnement_filter_helpers.dart';
import 'approvisionnements/approvisionnement_form_modal.dart';
import 'approvisionnements/approvisionnement_mobile_list.dart';
import 'approvisionnements/approvisionnement_search_period_bar.dart';

class ApprovisionScreen extends StatefulWidget {
  const ApprovisionScreen({super.key});

  @override
  State<ApprovisionScreen> createState() => _ApprovisionScreenState();
}

class _ApprovisionScreenState extends State<ApprovisionScreen> {
  String _search = '';
  int? _filterProductId;
  String _filterPeriod = 'all'; // 'all', 'today', 'yesterday', 'month', 'credit'
  String _sortBy = 'recent'; // 'recent', 'total_desc'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ApprovisionnementProvider>().load();
      context.read<SupplierProvider>().loadSuppliers();
    });
  }

  List<Approvisionnement> _filtered(List<Approvisionnement> allItems) => filterAndSortApprovisionnements(
        allItems,
        filterProductId: _filterProductId,
        filterPeriod: _filterPeriod,
        search: _search,
        sortBy: _sortBy,
      );

  Future<void> _showForm(BuildContext context, {Approvisionnement? approvisionnement}) async {
    if (approvisionnement == null) {
      final tenant = context.read<TenantProvider>();
      if (tenant.needsOperationalMagasin(isSale: false)) {
        final chosen = await SelectOperationalMagasinModal.show(context, isSale: false);
        if (chosen == null || !context.mounted) return;
        await tenant.selectMagasin(chosen);
        if (!context.mounted) return;
      }
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => ApprovisionFormModal(
        approvisionnement: approvisionnement,
        onSave: (newAppro) async {
          final approProvider = context.read<ApprovisionnementProvider>();
          final productProvider = context.read<ProductProvider>();
          final supplierProvider = context.read<SupplierProvider>();
          if (approvisionnement != null) {
            await approProvider.update(approvisionnement, newAppro);
          } else {
            await approProvider.add(newAppro);
          }
          await productProvider.load();
          await supplierProvider.loadSuppliers();
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
        title: const Text('Approvisionnements', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Exporter le registre',
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.ios_share_outlined, color: AppColors.primary, size: 20),
            ),
            onSelected: (val) {
              final settings = context.read<SettingsProvider>().settings;
              final products = context.read<ProductProvider>().products;
              final items = _filtered(context.read<ApprovisionnementProvider>().items);
              final periodName = approvisionnementPeriodLabel(_filterPeriod);
              if (val == 'excel') {
                ApprovisionnementExportService.exportApprovisionnementsExcel(context, items, products, periodName);
              } else if (val == 'pdf') {
                ApprovisionnementExportService.exportApprovisionnementsPdfReport(
                    context, items, products, periodName, settings);
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
            icon: const Icon(Icons.add, color: AppColors.primary),
            tooltip: 'Nouvel approvisionnement',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Consumer2<ApprovisionnementProvider, ProductProvider>(
        builder: (context, approProvider, productProvider, _) {
          final items = _filtered(approProvider.items);
          return Column(
            children: [
              ApprovisionSummaryBar(
                totalCount: approProvider.items.length,
                totalAmount: approProvider.totalAmount,
                formatter: formatter,
              ),
              ApprovisionSearchAndSortBar(
                onSearchChanged: (v) => setState(() => _search = v),
                onSortSelected: (val) => setState(() => _sortBy = val),
              ),
              ApprovisionPeriodFilterRow(
                filterPeriod: _filterPeriod,
                onPeriodChanged: (type) => setState(() => _filterPeriod = type),
              ),
              ApprovisionProductFilterRow(
                filterProductId: _filterProductId,
                products: productProvider.products,
                onProductSelected: (productId) {
                  setState(() => _filterProductId = productId);
                  context.read<ApprovisionnementProvider>().load(productId: productId);
                },
              ),
              Expanded(
                child: approProvider.loading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                    : items.isEmpty
                        ? const ApprovisionEmptyState()
                        : !isLargeScreen
                            ? ApprovisionMobileListView(
                                items: items,
                                products: productProvider.products,
                                formatter: formatter,
                                onTapItem: (a, prodName) => showApprovisionDetailModal(
                                  context,
                                  a,
                                  prodName,
                                  formatter,
                                  onDelete: () => showDeleteApprovisionDialog(context, a, approProvider, productProvider),
                                  onEdit: () => _showForm(context, approvisionnement: a),
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
                                      child: ApprovisionDataTable(
                                        items: items,
                                        products: productProvider.products,
                                        formatter: formatter,
                                        onEdit: (a) => _showForm(context, approvisionnement: a),
                                        onDelete: (a) =>
                                            showDeleteApprovisionDialog(context, a, approProvider, productProvider),
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
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('Nouvel réapprovisionnement'),
      ),
    );
  }
}
