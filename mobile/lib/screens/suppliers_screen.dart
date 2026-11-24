import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/supplier.dart';
import '../providers/settings_provider.dart';
import '../providers/supplier_provider.dart';
import '../services/supplier_export_service.dart';
import '../theme/app_theme.dart';
import 'suppliers/supplier_card_and_detail.dart';
import 'suppliers/supplier_detail_sheet.dart';
import 'suppliers/supplier_filters_and_stats.dart';
import 'suppliers/supplier_form_modal.dart';
import 'suppliers/supplier_import_service.dart';
import 'suppliers/supplier_payment_dialogs.dart';

class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({super.key});

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  String _search = '';
  String _filterCategory = 'all'; // 'all', 'debt', 'paid'
  String _sortBy = 'debt_desc'; // 'debt_desc', 'name_asc', 'recent'

  String _getFilterLabel() {
    if (_filterCategory == 'debt') return 'Fournisseurs avec dette';
    if (_filterCategory == 'paid') return 'Fournisseurs à jour';
    return 'Tous les fournisseurs';
  }

  void _showSupplierForm(BuildContext context, {Supplier? supplier}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => SupplierFormModal(supplier: supplier),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'fr_FR', symbol: 'F', decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Fournisseurs & Dettes', style: TextStyle(fontWeight: FontWeight.w700)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.maybePop(context),
          tooltip: 'Retour',
        ),
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
              final suppliers = context.read<SupplierProvider>().suppliers;
              final filterLabel = _getFilterLabel();
              if (val == 'excel') {
                SupplierExportService.exportSuppliersExcel(context, suppliers, filterLabel);
              } else if (val == 'pdf') {
                SupplierExportService.exportSuppliersPdfReport(context, suppliers, filterLabel, settings);
              } else if (val == 'import') {
                importSuppliersFromExcel(context);
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
              PopupMenuDivider(),
              PopupMenuItem(
                value: 'import',
                child: Row(
                  children: [
                    Icon(Icons.upload_file_outlined, size: 18, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text('Importer des fournisseurs'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: () => _showSupplierForm(context),
            icon: const Icon(Icons.group_add_outlined, color: AppColors.primary),
            tooltip: 'Nouveau fournisseur',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Consumer<SupplierProvider>(
        builder: (context, provider, _) {
          if (provider.loading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          final rawSuppliers = provider.suppliers.where((s) {
            final matchName = s.name.toLowerCase().contains(_search.toLowerCase());
            final matchContact = s.contactPerson?.toLowerCase().contains(_search.toLowerCase()) ?? false;
            final matchPhone = s.phone?.contains(_search) ?? false;
            return matchName || matchContact || matchPhone;
          }).toList();

          final suppliers = rawSuppliers.where((s) {
            if (_filterCategory == 'debt') return s.balance > 0;
            if (_filterCategory == 'paid') return s.balance <= 0;
            return true;
          }).toList();

          if (_sortBy == 'debt_desc') {
            suppliers.sort((a, b) => b.balance.compareTo(a.balance));
          } else if (_sortBy == 'name_asc') {
            suppliers.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
          } else if (_sortBy == 'recent') {
            suppliers.sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));
          }

          final debtCount = provider.suppliers.where((s) => s.balance > 0).length;

          return Column(
            children: [
              SupplierStatsBar(
                supplierCount: provider.suppliers.length,
                totalDettes: provider.totalDettes,
                formatter: formatter,
              ),
              SupplierSearchAndSortBar(
                onSearchChanged: (v) => setState(() => _search = v),
                onSortSelected: (val) => setState(() => _sortBy = val),
              ),
              SupplierFilterChipsRow(
                filterCategory: _filterCategory,
                totalCount: provider.suppliers.length,
                debtCount: debtCount,
                paidCount: provider.suppliers.length - debtCount,
                onFilterChanged: (category) => setState(() => _filterCategory = category),
              ),
              Expanded(
                child: suppliers.isEmpty
                    ? const SupplierEmptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: suppliers.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (ctx, i) {
                          final s = suppliers[i];
                          return SupplierCard(
                            supplier: s,
                            formatter: formatter,
                            onTap: () => showSupplierDetailSheet(
                              context,
                              s,
                              formatter,
                              onPay: () => showSupplierPaymentDialog(context, s, formatter),
                              onEdit: () => _showSupplierForm(context, supplier: s),
                              onDelete: () => confirmDeleteSupplierDialog(context, s, provider),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSupplierForm(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_business),
        label: const Text('Nouveau Fournisseur'),
      ),
    );
  }
}
