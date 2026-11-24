import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/product_provider.dart';
import '../theme/app_theme.dart';
import 'products/product_bulk_and_delete.dart';
import 'products/product_category_and_advanced_filters.dart';
import 'products/product_export_service.dart';
import 'products/product_form_modal.dart';
import 'products/product_grid_view.dart';
import 'products/product_header.dart';
import 'products/product_list_view.dart';
import 'products/product_search_bar.dart';
import 'products/product_stats_and_search.dart';
import 'products/product_stock_adjustment_dialog.dart';
import 'products/product_table_view.dart';

export 'products/product_form_modal.dart';

enum ProductViewMode { auto, list, grid, table }

class ProductsScreen extends StatefulWidget {
  final String? initialStatusFilter;
  final VoidCallback? onBackToHome;
  const ProductsScreen({super.key, this.initialStatusFilter, this.onBackToHome});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  String _search = '';
  int? _filterCategoryId;
  String? _filterStatut;
  final ProductViewMode _viewMode = ProductViewMode.auto;
  final Set<int> _selectedIds = {};
  String _sortBy = 'name_asc'; // 'name_asc', 'price_desc', 'stock_asc'

  @override
  void initState() {
    super.initState();
    if (widget.initialStatusFilter != null) {
      _filterStatut = widget.initialStatusFilter;
    }
  }

  @override
  void didUpdateWidget(covariant ProductsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialStatusFilter != oldWidget.initialStatusFilter &&
        widget.initialStatusFilter != null) {
      setState(() => _filterStatut = widget.initialStatusFilter);
    }
  }

  void _showForm(BuildContext context, {Product? product}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => ProductFormModal(
        product: product,
        onSave: (p) async {
          final provider = context.read<ProductProvider>();
          if (product == null) {
            await provider.add(p);
          } else {
            await provider.update(p);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'fr_FR', symbol: 'F', decimalDigits: 0);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          ProductsHeader(
            onBackToHome: widget.onBackToHome,
            onAddProduct: () => _showForm(context),
          ),
          ProductStatsBar(
            filterStatut: _filterStatut,
            onSelectStatut: (next) => setState(() => _filterStatut = next),
          ),
          ProductSearchAndSortBar(
            onSearchChanged: (v) => setState(() => _search = v),
            onSortSelected: (val) => setState(() => _sortBy = val),
          ),
          ProductCategoryFilterRow(
            filterCategoryId: _filterCategoryId,
            onCategorySelected: (catId) => setState(() => _filterCategoryId = catId),
            onOpenAdvancedFilters: () => showProductAdvancedFiltersSheet(
              context,
              initialCategoryId: _filterCategoryId,
              initialStatut: _filterStatut,
              onApply: (catId, statut) => setState(() {
                _filterCategoryId = catId;
                _filterStatut = statut;
              }),
              onReset: () => setState(() {
                _filterCategoryId = null;
                _filterStatut = null;
              }),
            ),
          ),
          if (_selectedIds.isNotEmpty)
            ProductBulkBar(
              count: _selectedIds.length,
              onExport: () {
                final sel = context
                    .read<ProductProvider>()
                    .products
                    .where((p) => p.id != null && _selectedIds.contains(p.id!))
                    .toList();
                showProductExportSheet(context, sel);
              },
              onDelete: () => showDeleteSelectedProductsDialog(
                context,
                _selectedIds,
                () => setState(() => _selectedIds.clear()),
              ),
              onClear: () => setState(() => _selectedIds.clear()),
            ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 600;
                final activeMode = _viewMode == ProductViewMode.auto
                    ? (isWide ? ProductViewMode.table : ProductViewMode.list)
                    : _viewMode;

                if (activeMode == ProductViewMode.grid) {
                  return ProductGridView(
                    search: _search,
                    filterCategoryId: _filterCategoryId,
                    filterStatut: _filterStatut,
                    sortBy: _sortBy,
                    formatter: formatter,
                    maxWidth: constraints.maxWidth,
                  );
                } else if (activeMode == ProductViewMode.list) {
                  return ProductListView(
                    search: _search,
                    filterCategoryId: _filterCategoryId,
                    filterStatut: _filterStatut,
                    sortBy: _sortBy,
                    formatter: formatter,
                    onAdjustStock: (p) => showProductStockAdjustmentDialog(context, p),
                    onEditProduct: (p) => _showForm(context, product: p),
                  );
                } else {
                  return ProductTableView(
                    search: _search,
                    filterCategoryId: _filterCategoryId,
                    filterStatut: _filterStatut,
                    sortBy: _sortBy,
                    formatter: formatter,
                    onAdjustStock: (p) => showProductStockAdjustmentDialog(context, p),
                    onEditProduct: (p) => _showForm(context, product: p),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
