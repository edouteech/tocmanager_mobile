import '../widgets/app_toast.dart';
import 'dart:collection';
import 'dart:io';
import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' as xl;
import '../models/product.dart';
import '../models/category.dart'; // used in export helpers
import '../providers/category_provider.dart';
import '../providers/product_provider.dart';
import '../providers/supplier_provider.dart';
import '../theme/app_theme.dart';
import '../utils/category_icon_helper.dart';
import 'product_detail_screen.dart';

class ProductsScreen extends StatefulWidget {
  final String? initialStatusFilter;
  final VoidCallback? onBackToHome;
  const ProductsScreen({super.key, this.initialStatusFilter, this.onBackToHome});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

enum ProductViewMode { auto, list, grid, table }

class _ProductsScreenState extends State<ProductsScreen> {
  String _search = '';
  int? _filterCategoryId;
  String? _filterStatut;
  final ProductViewMode _viewMode = ProductViewMode.auto;

  int? _pendingCategoryId;
  String? _pendingStatut;

  @override
  void initState() {
    super.initState();
    if (widget.initialStatusFilter != null) {
      _filterStatut = widget.initialStatusFilter;
      _pendingStatut = widget.initialStatusFilter;
    }
  }

  @override
  void didUpdateWidget(covariant ProductsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialStatusFilter != oldWidget.initialStatusFilter && widget.initialStatusFilter != null) {
      setState(() {
        _filterStatut = widget.initialStatusFilter;
        _pendingStatut = widget.initialStatusFilter;
      });
    }
  }

  final Set<int> _selectedIds = {};

  void _applyFilters() => setState(() {
        _filterCategoryId = _pendingCategoryId;
        _filterStatut = _pendingStatut;
      });

  void _resetFilters() => setState(() {
        _pendingCategoryId = null;
        _pendingStatut = null;
        _filterCategoryId = null;
        _filterStatut = null;
      });

  String _sortBy = 'name_asc'; // 'name_asc', 'price_desc', 'stock_asc'

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'fr_FR', symbol: 'F', decimalDigits: 0);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(context),
          _buildStats(),
          _buildSearchAndSortBar(),
          _buildFilterRow(),
          if (_selectedIds.isNotEmpty) _buildBulkBar(context),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 600;
                final activeMode = _viewMode == ProductViewMode.auto
                    ? (isWide ? ProductViewMode.table : ProductViewMode.list)
                    : _viewMode;

                if (activeMode == ProductViewMode.grid) {
                  return _buildGridView(formatter, constraints.maxWidth);
                } else if (activeMode == ProductViewMode.list) {
                  return _buildListView(formatter);
                } else {
                  return _buildTableView(formatter);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 16, 16, 14),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
                onPressed: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    widget.onBackToHome?.call();
                  }
                },
                tooltip: 'Retour',
              ),
              const Expanded(
                child: Text(
                  'Produits & Stocks',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                    letterSpacing: -0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Import / Export',
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.ios_share_outlined, color: AppColors.primary, size: 20),
                ),
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'export',
                    child: Row(
                      children: [
                        Icon(Icons.download_outlined, color: AppColors.primary, size: 18),
                        SizedBox(width: 8),
                        Text('Exporter la liste'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'import',
                    child: Row(
                      children: [
                        Icon(Icons.upload_file_outlined, color: AppColors.success, size: 18),
                        SizedBox(width: 8),
                        Text('Importer des produits'),
                      ],
                    ),
                  ),
                ],
                onSelected: (val) {
                  if (val == 'export') {
                    _showExportSheet(context, context.read<ProductProvider>().products);
                  } else if (val == 'import') {
                    _importExcel(context);
                  }
                },
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _showForm(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Nouveau'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndSortBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Rechercher un produit (nom, code)...',
                prefixIcon: const Icon(Icons.search, color: AppColors.textLight, size: 20),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            icon: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.sort_outlined, color: AppColors.primary, size: 20),
            ),
            tooltip: 'Trier les produits',
            onSelected: (val) => setState(() => _sortBy = val),
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'name_asc',
                child: Row(
                  children: [
                    Icon(Icons.sort_by_alpha, size: 16, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text('Nom (A - Z)'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'price_desc',
                child: Row(
                  children: [
                    Icon(Icons.arrow_downward, size: 16, color: AppColors.success),
                    SizedBox(width: 8),
                    Text('Prix le plus élevé'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'stock_asc',
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.danger),
                    SizedBox(width: 8),
                    Text('Stock le plus faible'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    final formatter = NumberFormat.currency(locale: 'fr_FR', symbol: 'F', decimalDigits: 0);

    return Consumer<ProductProvider>(
      builder: (context, provider, _) {
        final total = provider.products.length;
        final rupture = provider.products.where((p) => p.quantity == 0).length;
        final lowStock = provider.products.where((p) => p.isLowStock && p.quantity > 0).length;
        final totalValue = provider.products.fold<double>(0, (sum, p) => sum + (p.quantity * p.price));

        return Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Column(
            children: [
              Row(
                children: [
                  _statChip(
                    'Total ($total)',
                    _filterStatut == null ? 'Tous' : 'Filtrer',
                    AppColors.primary,
                    isSelected: _filterStatut == null,
                    onTap: () => setState(() => _filterStatut = null),
                  ),
                  const SizedBox(width: 6),
                  _statChip(
                    'Stock faible',
                    '$lowStock',
                    AppColors.warning,
                    isSelected: _filterStatut == 'faible',
                    onTap: () => setState(() {
                      _filterStatut = _filterStatut == 'faible' ? null : 'faible';
                    }),
                  ),
                  const SizedBox(width: 6),
                  _statChip(
                    'Rupture',
                    '$rupture',
                    AppColors.danger,
                    isSelected: _filterStatut == 'rupture',
                    onTap: () => setState(() {
                      _filterStatut = _filterStatut == 'rupture' ? null : 'rupture';
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.successLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.success.withAlpha(40)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.account_balance_wallet_outlined, size: 18, color: AppColors.success),
                    const SizedBox(width: 8),
                    const Text(
                      'Valeur totale du stock :',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark),
                    ),
                    const Spacer(),
                    Text(
                      formatter.format(totalValue),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.success),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statChip(String label, String value, Color color, {required bool isSelected, required VoidCallback onTap}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color : color.withAlpha(15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isSelected ? color : color.withAlpha(40)),
          ),
          child: Column(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: isSelected ? Colors.white : color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                  color: isSelected ? Colors.white.withAlpha(230) : AppColors.textMedium,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterRow() {
    return Consumer<CategoryProvider>(
      builder: (context, catProvider, _) => Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: Row(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _filterChip(null, 'Toutes cat.'),
                    ...catProvider.categories.map((c) => _filterChip(c.id, c.name)),
                  ],
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.tune, color: AppColors.primary, size: 20),
              onPressed: () => _showAdvancedFiltersSheet(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(int? catId, String label) {
    final selected = _filterCategoryId == catId;
    return GestureDetector(
      onTap: () => setState(() => _filterCategoryId = catId),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? AppColors.primary : AppColors.divider),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textMedium,
            fontSize: 11,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  void _showAdvancedFiltersSheet(BuildContext context) {
    final catProvider = context.read<CategoryProvider>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Filtres avancés',
                        style: TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        setSheetState(() => _resetFilters());
                        _resetFilters();
                      },
                      child: const Text('Réinitialiser'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('Catégorie',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                DropdownButtonFormField<int?>(
                  initialValue: _pendingCategoryId,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: [
                    const DropdownMenuItem<int?>(value: null, child: Text('Toutes les catégories')),
                    ...catProvider.categories
                        .map((c) => DropdownMenuItem<int?>(value: c.id, child: Text(c.name))),
                  ],
                  onChanged: (v) => setSheetState(() => _pendingCategoryId = v),
                ),
                const SizedBox(height: 14),
                const Text('Statut du stock',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String?>(
                  initialValue: _pendingStatut,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: const [
                    DropdownMenuItem<String?>(value: null, child: Text('Tous les statuts')),
                    DropdownMenuItem<String?>(value: 'en_stock', child: Text('En stock')),
                    DropdownMenuItem<String?>(value: 'lowStock', child: Text('Stock faible & Rupture')),
                    DropdownMenuItem<String?>(value: 'faible', child: Text('Stock faible uniquement')),
                    DropdownMenuItem<String?>(value: 'rupture', child: Text('Rupture uniquement')),
                  ],
                  onChanged: (v) => setSheetState(() => _pendingStatut = v),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      _applyFilters();
                      Navigator.pop(ctx);
                    },
                    child: const Text('Appliquer les filtres'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Product> _getFilteredProducts(ProductProvider productProvider) {
    final products = productProvider.products.where((p) {
      final matchSearch = p.name.toLowerCase().contains(_search.toLowerCase()) ||
          (p.barcode?.toLowerCase().contains(_search.toLowerCase()) ?? false);
      final matchCat = _filterCategoryId == null || p.categoryId == _filterCategoryId;
      final isRupture = p.quantity == 0;
      final isFaible = p.isLowStock && !isRupture;
      final matchStatut = _filterStatut == null ||
          (_filterStatut == 'lowStock' && p.isLowStock) ||
          (_filterStatut == 'rupture' && isRupture) ||
          (_filterStatut == 'faible' && isFaible) ||
          (_filterStatut == 'en_stock' && !p.isLowStock);
      return matchSearch && matchCat && matchStatut;
    }).toList();

    if (_sortBy == 'price_desc') {
      products.sort((a, b) => b.price.compareTo(a.price));
    } else if (_sortBy == 'stock_asc') {
      products.sort((a, b) => a.quantity.compareTo(b.quantity));
    } else if (_sortBy == 'name_asc') {
      products.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    }

    return products;
  }

  Widget _buildTableView(NumberFormat formatter) {
    return Consumer2<ProductProvider, CategoryProvider>(
      builder: (context, productProvider, catProvider, _) {
        if (productProvider.loading) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        final products = _getFilteredProducts(productProvider);

        if (products.isEmpty) return _buildEmptyProductsView();

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 100),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowHeight: 40,
                  dataRowMinHeight: 52,
                  dataRowMaxHeight: 52,
                  columnSpacing: 14,
                  horizontalMargin: 12,
                  headingRowColor: WidgetStateProperty.all(AppColors.primaryLight),
                  dividerThickness: 1,
                  columns: const [
                    DataColumn(label: SizedBox(width: 40)),
                    DataColumn(label: Text('Produit', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.primary))),
                    DataColumn(label: Text('Catégorie', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.primary))),
                    DataColumn(label: Text('Prix vente', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.primary)), numeric: true),
                    DataColumn(label: Text('Stock', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.primary)), numeric: true),
                    DataColumn(label: Text('Statut', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.primary))),
                    DataColumn(label: SizedBox(width: 80)),
                  ],
                  rows: products.asMap().entries.map((entry) {
                    final i = entry.key;
                    final p = entry.value;
                    final cat = catProvider.categories.where((c) => c.id == p.categoryId).firstOrNull;
                    final catColor = cat != null ? Color(cat.color) : AppColors.primary;
                    final isRupture = p.quantity == 0;
                    final isFaible = p.isLowStock && !isRupture;
                    final statusColor = isRupture ? AppColors.danger : isFaible ? AppColors.warning : AppColors.success;
                    final statusLabel = isRupture ? 'Rupture' : isFaible ? 'Stock faible' : 'En stock';

                    return DataRow(
                      color: WidgetStateProperty.all(i.isEven ? Colors.white : const Color(0xFFF8FBFF)),
                      cells: [
                        DataCell(_productThumb(p, catColor, cat, size: 32)),
                        DataCell(Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textDark))),
                        DataCell(Text(cat?.name ?? '—', style: const TextStyle(color: AppColors.textMedium, fontSize: 12))),
                        DataCell(Text(formatter.format(p.price), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.primary))),
                        DataCell(Text('${p.quantity.toStringAsFixed(p.quantity.truncateToDouble() == p.quantity ? 0 : 1)} ${p.unit}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                        DataCell(Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withAlpha(25),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(statusLabel, style: TextStyle(color: statusColor, fontWeight: FontWeight.w600, fontSize: 11)),
                          ),
                        )),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _actionBtn(
                                icon: Icons.edit_note,
                                color: AppColors.purple,
                                bg: AppColors.purple.withAlpha(20),
                                onTap: () => _showStockAdjustmentDialog(context, p),
                              ),
                              const SizedBox(width: 6),
                              _actionBtn(
                                icon: Icons.visibility_outlined,
                                color: AppColors.success,
                                bg: AppColors.successLight,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => ProductDetailScreen(product: p)),
                                ),
                              ),
                              const SizedBox(width: 6),
                              _actionBtn(
                                icon: Icons.edit_outlined,
                                color: AppColors.primary,
                                bg: AppColors.primaryLight,
                                onTap: () => _showForm(context, product: p),
                              ),
                              const SizedBox(width: 6),
                              _actionBtn(
                                icon: Icons.delete_outline,
                                color: AppColors.danger,
                                bg: AppColors.dangerLight,
                                onTap: () => _confirmDelete(context, p, productProvider),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _productThumb(Product p, Color catColor, dynamic cat, {double size = 40}) {
    if (p.imagePath != null) {
      final file = File(p.imagePath!);
      return ClipRRect(
        borderRadius: BorderRadius.circular(size > 44 ? 12 : 8),
        child: Image.file(
          file,
          width: size, height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _catIcon(catColor, cat, size: size),
        ),
      );
    }
    return _catIcon(catColor, cat, size: size);
  }

  Widget _catIcon(Color catColor, dynamic cat, {double size = 40}) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        color: catColor.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        cat != null ? CategoryIconHelper.getIcon(cat.icon) : Icons.inventory_2_outlined,
        color: catColor, size: 28,
      ),
    );
  }

  Widget _actionBtn({
    required IconData icon,
    required Color color,
    required Color bg,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 28, height: 28,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: color, size: 14),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Product product, ProductProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Supprimer', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text('Supprimer "${product.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              await provider.delete(product.id!);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _showStockAdjustmentDialog(BuildContext context, Product product) {
    final qtyCtrl = TextEditingController(text: '1');
    String mode = 'add'; // 'add', 'remove', 'set'

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final double currentQty = product.quantity;
            final double inputQty = double.tryParse(qtyCtrl.text.trim()) ?? 0;
            double newQty = currentQty;
            if (mode == 'add') {
              newQty = currentQty + inputQty;
            } else if (mode == 'remove') {
              newQty = (currentQty - inputQty).clamp(0, double.infinity);
            } else if (mode == 'set') {
              newQty = inputQty.clamp(0, double.infinity);
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
                top: 20,
                left: 20,
                right: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.edit_note, color: AppColors.primary, size: 24),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Ajuster le stock : ${product.name}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textDark),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withAlpha(40)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            const Text('Stock actuel', style: TextStyle(fontSize: 11, color: AppColors.textMedium)),
                            const SizedBox(height: 2),
                            Text(
                              '${currentQty.toStringAsFixed(currentQty.truncateToDouble() == currentQty ? 0 : 1)} ${product.unit}',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark),
                            ),
                          ],
                        ),
                        const Icon(Icons.arrow_forward, color: AppColors.primary, size: 18),
                        Column(
                          children: [
                            const Text('Nouveau stock', style: TextStyle(fontSize: 11, color: AppColors.textMedium)),
                            const SizedBox(height: 2),
                            Text(
                              '${newQty.toStringAsFixed(newQty.truncateToDouble() == newQty ? 0 : 1)} ${product.unit}',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.primary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('+ Ajouter', style: TextStyle(fontSize: 12))),
                          selected: mode == 'add',
                          selectedColor: AppColors.success,
                          labelStyle: TextStyle(color: mode == 'add' ? Colors.white : AppColors.textDark, fontWeight: FontWeight.w700),
                          onSelected: (val) {
                            if (val) setSheetState(() => mode = 'add');
                          },
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('- Retirer', style: TextStyle(fontSize: 12))),
                          selected: mode == 'remove',
                          selectedColor: AppColors.danger,
                          labelStyle: TextStyle(color: mode == 'remove' ? Colors.white : AppColors.textDark, fontWeight: FontWeight.w700),
                          onSelected: (val) {
                            if (val) setSheetState(() => mode = 'remove');
                          },
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('= Définir', style: TextStyle(fontSize: 12))),
                          selected: mode == 'set',
                          selectedColor: AppColors.purple,
                          labelStyle: TextStyle(color: mode == 'set' ? Colors.white : AppColors.textDark, fontWeight: FontWeight.w700),
                          onSelected: (val) {
                            if (val) setSheetState(() => mode = 'set');
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: qtyCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: mode == 'set' ? 'Nouvelle quantité exacte' : 'Nombre d\'unités',
                      suffixText: product.unit,
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.divider),
                      ),
                    ),
                    onChanged: (_) => setSheetState(() {}),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final updatedProduct = product.copyWith(quantity: newQty);
                        await context.read<ProductProvider>().update(updatedProduct);
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          AppToast.showSuccess(
                            context,
                            'Stock de ${product.name} mis à jour : ${newQty.toStringAsFixed(newQty.truncateToDouble() == newQty ? 0 : 1)} ${product.unit}',
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: const Icon(Icons.check, size: 20),
                      label: const Text('Valider le réajustement', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showForm(BuildContext context, {Product? product}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
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

  // ── Bulk action bar ────────────────────────────────────────────────────────

  Widget _buildBulkBar(BuildContext context) {
    final count = _selectedIds.length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppColors.primary,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(35),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count sélectionné${count > 1 ? 's' : ''}',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          const Spacer(),
          _bulkBtn(Icons.download_outlined, 'Exporter', () {
            final sel = context.read<ProductProvider>().products
                .where((p) => p.id != null && _selectedIds.contains(p.id!)).toList();
            _showExportSheet(context, sel);
          }),
          const SizedBox(width: 8),
          _bulkBtn(Icons.delete_outline, 'Supprimer', () => _deleteSelected(context)),
          const SizedBox(width: 4),
          IconButton(
            onPressed: () => setState(() => _selectedIds.clear()),
            icon: const Icon(Icons.close, color: Colors.white, size: 18),
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildListView(NumberFormat formatter) {
    return Consumer2<ProductProvider, CategoryProvider>(
      builder: (context, productProvider, catProvider, _) {
        if (productProvider.loading) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        final products = _getFilteredProducts(productProvider);

        if (products.isEmpty) return _buildEmptyProductsView();

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 100),
          itemCount: products.length,
          itemBuilder: (ctx, i) {
            final p = products[i];
            final cat = catProvider.categories.where((c) => c.id == p.categoryId).firstOrNull;
            final catColor = cat != null ? Color(cat.color) : AppColors.primary;
            final isRupture = p.quantity == 0;
            final isFaible = p.isLowStock && !isRupture;
            final statusColor = isRupture ? AppColors.danger : isFaible ? AppColors.warning : AppColors.success;
            final statusText = isRupture ? 'Rupture' : isFaible ? 'Stock faible' : 'En stock';

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.divider),
                boxShadow: [
                  BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 6, offset: const Offset(0, 2)),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                child: ListTile(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ProductDetailScreen(product: p)),
                    );
                  },
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  leading: _productThumb(p, catColor, cat, size: 38),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          p.name,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textDark),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        formatter.format(p.price),
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.primary),
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (cat != null)
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: catColor.withAlpha(20),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  cat.name,
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: catColor),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          if (cat != null) const SizedBox(width: 6),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: statusColor.withAlpha(20),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '$statusText (${p.quantity.toStringAsFixed(p.quantity.truncateToDouble() == p.quantity ? 0 : 1)} ${p.unit})',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (p.quantity > 0) ...[
                        const SizedBox(height: 3),
                        Text(
                          'Valeur stock: ${formatter.format(p.quantity * p.price)}',
                          style: const TextStyle(fontSize: 10, color: AppColors.textLight, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _actionBtn(
                        icon: Icons.edit_note,
                        color: AppColors.purple,
                        bg: AppColors.purple.withAlpha(20),
                        onTap: () => _showStockAdjustmentDialog(context, p),
                      ),
                      const SizedBox(width: 4),
                      _actionBtn(
                        icon: Icons.edit_outlined,
                        color: AppColors.textMedium,
                        bg: AppColors.background,
                        onTap: () => _showForm(context, product: p),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildGridView(NumberFormat formatter, double maxWidth) {
    final crossAxisCount = maxWidth >= 900 ? 4 : maxWidth >= 600 ? 3 : 2;

    return Consumer2<ProductProvider, CategoryProvider>(
      builder: (context, productProvider, catProvider, _) {
        if (productProvider.loading) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        final products = productProvider.products.where((p) {
          final matchSearch = p.name.toLowerCase().contains(_search.toLowerCase());
          final matchCat = _filterCategoryId == null || p.categoryId == _filterCategoryId;
          final isRupture = p.quantity == 0;
          final isFaible = p.isLowStock && !isRupture;
          final matchStatut = _filterStatut == null ||
              (_filterStatut == 'lowStock' && p.isLowStock) ||
              (_filterStatut == 'rupture' && isRupture) ||
              (_filterStatut == 'faible' && isFaible) ||
              (_filterStatut == 'en_stock' && !p.isLowStock);
          return matchSearch && matchCat && matchStatut;
        }).toList();

        if (products.isEmpty) return _buildEmptyProductsView();

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 100),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 0.85,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
          ),
          itemCount: products.length,
          itemBuilder: (ctx, i) {
            final p = products[i];
            final cat = catProvider.categories.where((c) => c.id == p.categoryId).firstOrNull;
            final catColor = cat != null ? Color(cat.color) : AppColors.primary;
            final isRupture = p.quantity == 0;
            final isFaible = p.isLowStock && !isRupture;
            final statusColor = isRupture ? AppColors.danger : isFaible ? AppColors.warning : AppColors.success;
            final statusText = isRupture ? 'Rupture' : isFaible ? 'Stock faible' : 'En stock';

            return InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ProductDetailScreen(product: p)),
                );
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Center(
                        child: _productThumb(p, catColor, cat, size: 38),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      p.name,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textDark),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatter.format(p.price),
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.primary),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withAlpha(20),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '$statusText (${p.quantity.toStringAsFixed(0)})',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: statusColor),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyProductsView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: AppColors.primaryLight, shape: BoxShape.circle,
            ),
            child: const Icon(Icons.inventory_2_outlined, size: 48, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          const Text('Aucun produit',
              style: TextStyle(
                  color: AppColors.textDark, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          const Text('Ajoutez votre premier produit',
              style: TextStyle(color: AppColors.textMedium)),
        ],
      ),
    );
  }

  Widget _bulkBtn(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(35),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withAlpha(60)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 14),
            const SizedBox(width: 5),
            Text(label,
                style: const TextStyle(
                    color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  // ── Export sheet ───────────────────────────────────────────────────────────

  void _showExportSheet(BuildContext context, List<Product> products) {
    final cats = context.read<CategoryProvider>().categories;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Exporter ${products.length} produit${products.length > 1 ? 's' : ''}',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark),
              ),
              const SizedBox(height: 4),
              const Text("Choisissez le format d'export",
                  style: TextStyle(color: AppColors.textMedium, fontSize: 12)),
              const SizedBox(height: 12),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.table_chart_outlined, color: AppColors.success),
                title: const Text('Excel (.xlsx)',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Microsoft Excel, LibreOffice, Google Sheets'),
                onTap: () {
                  Navigator.pop(ctx);
                  _exportExcel(context, products, cats);
                },
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf_outlined, color: AppColors.danger),
                title: const Text('PDF', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Prêt à imprimer ou partager'),
                onTap: () {
                  Navigator.pop(ctx);
                  _exportPdf(context, products, cats);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // ── Excel export ───────────────────────────────────────────────────────────

  Future<void> _exportExcel(
      BuildContext context, List<Product> products, List<Category> categories) async {
    try {
      final excel = xl.Excel.createExcel();
      excel.rename('Sheet1', 'Produits');
      final sheet = excel['Produits'];

      sheet.appendRow([
        'ID', "Nom", 'Catégorie', "Prix d'achat (F)", 'Prix de vente (F)',
        'Quantité', 'Stock min.', 'Valorisation (F)', 'Statut', 'Créé le',
      ].map(xl.TextCellValue.new).toList());

      final dateFmt = DateFormat('dd/MM/yyyy');
      for (final p in products) {
        final cat = categories.where((c) => c.id == p.categoryId).firstOrNull;
        final status = p.quantity == 0
            ? 'Rupture'
            : p.isLowStock
                ? 'Stock faible'
                : 'En stock';
        sheet.appendRow([
          xl.IntCellValue(p.id ?? 0),
          xl.TextCellValue(p.name),
          xl.TextCellValue(cat?.name ?? ''),
          xl.DoubleCellValue(p.costPrice),
          xl.DoubleCellValue(p.price),
          xl.DoubleCellValue(p.quantity),
          xl.DoubleCellValue(p.alertQuantity),
          xl.DoubleCellValue(p.stockValue),
          xl.TextCellValue(status),
          xl.TextCellValue(dateFmt.format(p.createdAt)),
        ]);
      }

      final bytes = excel.encode();
      if (bytes == null) throw Exception('Échec encodage');

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/produits_${DateTime.now().millisecondsSinceEpoch}.xlsx');
      await file.writeAsBytes(bytes);

      await Share.shareXFiles([XFile(file.path)], text: 'Export produits — tocmanager');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur export: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  // ── PDF export ─────────────────────────────────────────────────────────────

  Future<void> _exportPdf(
      BuildContext context, List<Product> products, List<Category> categories) async {
    try {
      final fontRegular = await PdfGoogleFonts.robotoRegular();
      final fontBold = await PdfGoogleFonts.robotoBold();
      final doc = pw.Document();
      final numFmt = NumberFormat('#,##0', 'fr_FR');

      final tableData = products.map((p) {
        final cat = categories.where((c) => c.id == p.categoryId).firstOrNull;
        final status = p.quantity == 0
            ? 'Rupture'
            : p.isLowStock
                ? 'Faible'
                : 'OK';
        return [
          p.name,
          cat?.name ?? '—',
          '${numFmt.format(p.costPrice)} F',
          '${numFmt.format(p.price)} F',
          p.quantity.toStringAsFixed(0),
          '${numFmt.format(p.stockValue)} F',
          status,
        ];
      }).toList();

      doc.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        header: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Liste des produits — tocmanager',
                style: pw.TextStyle(font: fontBold, fontSize: 16)),
            pw.SizedBox(height: 4),
            pw.Text(
              'Généré le ${DateFormat('dd/MM/yyyy à HH:mm').format(DateTime.now())} · ${products.length} produit${products.length > 1 ? 's' : ''}',
              style: pw.TextStyle(font: fontRegular, fontSize: 9, color: PdfColors.grey600),
            ),
            pw.Divider(),
            pw.SizedBox(height: 4),
          ],
        ),
        build: (ctx) => [
          pw.TableHelper.fromTextArray(
            headers: ['Nom', 'Catégorie', "P. achat", 'P. vente', 'Qté', 'Valorisation', 'Statut'],
            data: tableData,
            headerStyle: pw.TextStyle(font: fontBold, fontSize: 9),
            cellStyle: pw.TextStyle(font: fontRegular, fontSize: 8),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue50),
            rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
            oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            columnWidths: const {
              0: pw.FlexColumnWidth(2.5),
              1: pw.FlexColumnWidth(1.5),
              2: pw.FlexColumnWidth(1.3),
              3: pw.FlexColumnWidth(1.3),
              4: pw.FlexColumnWidth(0.8),
              5: pw.FlexColumnWidth(1.5),
              6: pw.FlexColumnWidth(1.0),
            },
          ),
        ],
      ));

      await Printing.sharePdf(
        bytes: await doc.save(),
        filename: 'produits_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur PDF: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  // ── Excel import ───────────────────────────────────────────────────────────

  Future<void> _importExcel(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
      withData: true,
    );
    if (result == null || result.files.single.bytes == null) return;

    try {
      final excel = xl.Excel.decodeBytes(result.files.single.bytes!);
      final sheetName = excel.tables.keys.first;
      final sheet = excel.tables[sheetName]!;

      if (sheet.rows.length < 2) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Fichier vide ou sans données.')),
          );
        }
        return;
      }

      double parseNum(List<xl.Data?> row, int col) {
        if (row.length <= col) return 0;
        final v = row[col]?.value;
        if (v is xl.IntCellValue) return v.value.toDouble();
        if (v is xl.DoubleCellValue) return v.value;
        return double.tryParse(v?.toString() ?? '') ?? 0;
      }

      final toImport = <Map<String, dynamic>>[];
      for (var i = 1; i < sheet.rows.length; i++) {
        final row = sheet.rows[i];
        final name = (row.length > 1 ? row[1]?.value?.toString() : null)?.trim() ?? '';
        if (name.isEmpty) continue;
        toImport.add({
          'name': name,
          'category': row.length > 2 ? (row[2]?.value?.toString() ?? '') : '',
          'costPrice': parseNum(row, 3),
          'price': parseNum(row, 4),
          'quantity': parseNum(row, 5),
          'alertQuantity': parseNum(row, 6),
        });
      }

      if (toImport.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Aucune ligne valide trouvée.')),
          );
        }
        return;
      }

      if (!context.mounted) return;
      _showImportPreview(context, toImport);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erreur de lecture: $e'),
              backgroundColor: AppColors.danger),
        );
      }
    }
  }

  void _showImportPreview(BuildContext context, List<Map<String, dynamic>> rows) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        final preview = rows.take(4).toList();
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.upload_file_outlined, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Text(
                    'Importer ${rows.length} produit${rows.length > 1 ? 's' : ''}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ]),
                const SizedBox(height: 6),
                Text(
                  '${rows.length} ligne${rows.length > 1 ? 's' : ''} valide${rows.length > 1 ? 's' : ''} trouvée${rows.length > 1 ? 's' : ''} dans le fichier.',
                  style: const TextStyle(color: AppColors.textMedium, fontSize: 13),
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                ...preview.map((r) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(children: [
                        const Icon(Icons.chevron_right, size: 16, color: AppColors.textLight),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(r['name'] as String,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 13),
                              overflow: TextOverflow.ellipsis),
                        ),
                        Text(
                          'Qté: ${(r['quantity'] as double).toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textMedium),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${(r['price'] as double).toStringAsFixed(0)} F',
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600),
                        ),
                      ]),
                    )),
                if (rows.length > 4) ...[
                  Text(
                    '… et ${rows.length - 4} autre${rows.length - 4 > 1 ? 's' : ''}',
                    style: const TextStyle(color: AppColors.textLight, fontSize: 11),
                  ),
                  const SizedBox(height: 4),
                ],
                const Divider(height: 1),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await _confirmImport(context, rows);
                    },
                    child: const Text("Confirmer l'importation"),
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Annuler'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmImport(
      BuildContext context, List<Map<String, dynamic>> rows) async {
    final productProvider = context.read<ProductProvider>();
    final catProvider = context.read<CategoryProvider>();
    final now = DateTime.now();
    int imported = 0;

    for (final row in rows) {
      int? catId;
      final catName = (row['category'] as String).toLowerCase().trim();
      if (catName.isNotEmpty) {
        catId = catProvider.categories
            .where((c) => c.name.toLowerCase() == catName)
            .firstOrNull
            ?.id;
      }
      await productProvider.add(Product(
        name: row['name'] as String,
        categoryId: catId,
        price: row['price'] as double,
        costPrice: row['costPrice'] as double,
        quantity: row['quantity'] as double,
        alertQuantity:
            (row['alertQuantity'] as double) > 0 ? row['alertQuantity'] as double : 5,
        unit: 'pce',
        createdAt: now,
        updatedAt: now,
      ));
      imported++;
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            '$imported produit${imported > 1 ? 's' : ''} importé${imported > 1 ? 's' : ''} avec succès.'),
        backgroundColor: AppColors.success,
      ));
    }
  }

  // ── Delete selected ────────────────────────────────────────────────────────

  void _deleteSelected(BuildContext context) {
    final count = _selectedIds.length;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Supprimer la sélection',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text(
            'Supprimer $count produit${count > 1 ? 's' : ''} sélectionné${count > 1 ? 's' : ''} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final provider = context.read<ProductProvider>();
              for (final id in _selectedIds.toList()) {
                await provider.delete(id);
              }
              setState(() => _selectedIds.clear());
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class ProductFormModal extends StatefulWidget {
  final Product? product;
  final String? initialName;
  final double? initialPrice;
  final Future<void> Function(Product) onSave;

  const ProductFormModal({
    super.key,
    this.product,
    this.initialName,
    this.initialPrice,
    required this.onSave,
  });

  @override
  State<ProductFormModal> createState() => _ProductFormModalState();
}

class _ProductFormModalState extends State<ProductFormModal> {
  final _formKey = GlobalKey<FormState>();
  late final _nameCtrl = TextEditingController(text: widget.product?.name ?? widget.initialName ?? '');
  late final _descCtrl = TextEditingController(text: widget.product?.description ?? '');
  late final _priceCtrl = TextEditingController(
      text: widget.product != null
          ? widget.product!.price.toStringAsFixed(0)
          : (widget.initialPrice != null && widget.initialPrice! > 0
              ? widget.initialPrice!.toStringAsFixed(0)
              : ''));
  late final _priceSemiWholesaleCtrl = TextEditingController(
      text: widget.product != null && widget.product!.priceSemiWholesale > 0
          ? widget.product!.priceSemiWholesale.toStringAsFixed(0)
          : '');
  late final _minQtySemiWholesaleCtrl = TextEditingController(
      text: widget.product != null && widget.product!.minQtySemiWholesale > 0
          ? widget.product!.minQtySemiWholesale.toStringAsFixed(0)
          : '');
  late final _priceWholesaleCtrl = TextEditingController(
      text: widget.product != null && widget.product!.priceWholesale > 0
          ? widget.product!.priceWholesale.toStringAsFixed(0)
          : '');
  late final _minQtyWholesaleCtrl = TextEditingController(
      text: widget.product != null && widget.product!.minQtyWholesale > 0
          ? widget.product!.minQtyWholesale.toStringAsFixed(0)
          : '');
  late final _costCtrl = TextEditingController(
      text: widget.product != null ? widget.product!.costPrice.toStringAsFixed(0) : '');
  late final _qtyCtrl = TextEditingController(
      text: widget.product != null ? widget.product!.quantity.toStringAsFixed(0) : '');
  late final _alertCtrl = TextEditingController(
      text: widget.product != null ? widget.product!.alertQuantity.toStringAsFixed(0) : '5');
  late final TextEditingController _categoryCtrl;
  final FocusNode _categoryFocusNode = FocusNode();
  late int? _categoryId = widget.product?.categoryId;
  late int? _supplierId = widget.product?.supplierId;
  String? _imagePath;
  Uint8List? _imageBytes;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _imagePath = widget.product?.imagePath;
    String initCatName = '';
    if (widget.product?.categoryId != null) {
      final cat = context
          .read<CategoryProvider>()
          .categories
          .where((c) => c.id == widget.product!.categoryId)
          .firstOrNull;
      if (cat != null) initCatName = cat.name;
    }
    _categoryCtrl = TextEditingController(text: initCatName);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SupplierProvider>().loadSuppliers();
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _categoryCtrl.dispose();
    _categoryFocusNode.dispose();
    _priceCtrl.dispose();
    _priceSemiWholesaleCtrl.dispose();
    _minQtySemiWholesaleCtrl.dispose();
    _priceWholesaleCtrl.dispose();
    _minQtyWholesaleCtrl.dispose();
    _costCtrl.dispose();
    _qtyCtrl.dispose();
    _alertCtrl.dispose();
    super.dispose();
  }

  // ── Image helpers ──────────────────────────────────────────────────────────

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
              title: const Text('Galerie'),
              onTap: () { Navigator.pop(ctx); _pickAndProcess(ImageSource.gallery); },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
              title: const Text('Appareil photo'),
              onTap: () { Navigator.pop(ctx); _pickAndProcess(ImageSource.camera); },
            ),
            if (_imageBytes != null || _imagePath != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.danger),
                title: const Text('Supprimer la photo',
                    style: TextStyle(color: AppColors.danger)),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() { _imageBytes = null; _imagePath = null; });
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndProcess(ImageSource source) async {
    final xFile = await ImagePicker().pickImage(
        source: source, maxWidth: 1200, maxHeight: 1200);
    if (xFile == null || !mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _ImageProcessorSheet(
        sourcePath: xFile.path,
        onConfirm: (bytes) => setState(() => _imageBytes = bytes),
      ),
    );
  }

  Future<String?> _persistImage() async {
    if (_imageBytes == null) return _imagePath;
    if (_imagePath != null) {
      try { await File(_imagePath!).delete(); } catch (_) {}
    }
    final dir = await getApplicationDocumentsDirectory();
    final imgDir = Directory('${dir.path}/product_images');
    await imgDir.create(recursive: true);
    final path = '${imgDir.path}/${DateTime.now().millisecondsSinceEpoch}.png';
    await File(path).writeAsBytes(_imageBytes!);
    return path;
  }

  void _showAddCategoryDialog(BuildContext context) {
    final catNameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Nouvelle catégorie', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        content: TextField(
          controller: catNameCtrl,
          decoration: const InputDecoration(
            labelText: 'Nom de la catégorie',
            hintText: 'Ex: Électronique, Boissons...',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = catNameCtrl.text.trim();
              if (name.isNotEmpty) {
                final newCat = Category(
                  name: name,
                  color: AppColors.primary.toARGB32(),
                  icon: Icons.category.codePoint,
                  createdAt: DateTime.now(),
                );
                final catProvider = context.read<CategoryProvider>();
                await catProvider.add(newCat);
                final createdCat = catProvider.categories.where((c) => c.name == name).firstOrNull;
                if (createdCat != null) {
                  setState(() {
                    _categoryId = createdCat.id;
                  });
                }
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Créer'),
          ),
        ],
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.product != null;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    isEdit ? 'Modifier le produit' : 'Nouveau produit',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textDark),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: AppColors.textMedium),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Photo + Nom
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: _showImageSourceSheet,
                  child: Container(
                    width: 76, height: 76,
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: AppColors.divider, style: BorderStyle.solid),
                    ),
                    child: _buildImagePreview(),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Nom du produit *',
                        hintText: 'Ex: Smartphone X12'),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Nom du produit obligatoire';
                      if (val.trim().length < 2) return 'Au moins 2 caractères';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                  labelText: 'Description', hintText: 'Description optionnelle'),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Consumer<CategoryProvider>(
                    builder: (context, catProvider, _) {
                      return RawAutocomplete<Category>(
                        textEditingController: _categoryCtrl,
                        focusNode: _categoryFocusNode,
                        displayStringForOption: (Category option) => option.name,
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          final query = textEditingValue.text.trim().toLowerCase();
                          if (query.isEmpty) {
                            return catProvider.categories;
                          }
                          return catProvider.categories.where(
                            (Category c) => c.name.toLowerCase().contains(query),
                          );
                        },
                        onSelected: (Category selection) {
                          _categoryId = selection.id;
                          _categoryCtrl.text = selection.name;
                          _categoryCtrl.selection = TextSelection.fromPosition(
                            TextPosition(offset: selection.name.length),
                          );
                        },
                        fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                          return TextFormField(
                            controller: controller,
                            focusNode: focusNode,
                            decoration: InputDecoration(
                              labelText: 'Catégorie',
                              hintText: 'Sélectionner ou saisir une catégorie',
                              prefixIcon: const Icon(Icons.category_outlined, size: 20),
                              suffixIcon: controller.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 18),
                                      onPressed: () {
                                        controller.clear();
                                        setState(() => _categoryId = null);
                                      },
                                    )
                                  : null,
                              filled: true,
                              fillColor: AppColors.primarySurface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onChanged: (val) {
                              final match = catProvider.categories
                                  .where((c) => c.name.toLowerCase() == val.trim().toLowerCase())
                                  .firstOrNull;
                              setState(() {
                                _categoryId = match?.id;
                              });
                            },
                          );
                        },
                        optionsViewBuilder: (context, onSelected, options) {
                          final query = _categoryCtrl.text.trim();
                          final bool hasExactMatch = catProvider.categories.any(
                            (c) => c.name.toLowerCase() == query.toLowerCase(),
                          );

                          return Align(
                            alignment: Alignment.topLeft,
                            child: Material(
                              elevation: 6,
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.white,
                              child: Container(
                                width: MediaQuery.of(context).size.width - 90,
                                constraints: const BoxConstraints(maxHeight: 200),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.divider),
                                ),
                                child: ListView(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  shrinkWrap: true,
                                  children: [
                                    ...options.map((Category option) {
                                      return ListTile(
                                        dense: true,
                                        leading: const CircleAvatar(
                                          radius: 12,
                                          backgroundColor: AppColors.primarySurface,
                                          child: Icon(Icons.category, size: 14, color: AppColors.primary),
                                        ),
                                        title: Text(
                                          option.name,
                                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                        ),
                                        onTap: () => onSelected(option),
                                      );
                                    }),
                                    if (query.isNotEmpty && !hasExactMatch) ...[
                                      if (options.isNotEmpty) const Divider(height: 1, color: AppColors.divider),
                                      ListTile(
                                        dense: true,
                                        leading: const CircleAvatar(
                                          radius: 12,
                                          backgroundColor: AppColors.primaryLight,
                                          child: Icon(Icons.add, size: 14, color: AppColors.primary),
                                        ),
                                        title: Text(
                                          'Créer la catégorie "$query"',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                        onTap: () {
                                          _categoryCtrl.text = query;
                                          FocusScope.of(context).unfocus();
                                        },
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Créer une catégorie',
                  onPressed: () => _showAddCategoryDialog(context),
                  icon: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withAlpha(40)),
                    ),
                    child: const Icon(Icons.add, color: AppColors.primary, size: 20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // --- Fournisseur (Facultatif) ---
            Consumer<SupplierProvider>(
              builder: (context, suppProvider, _) {
                final validSupplierId = suppProvider.suppliers.any((s) => s.id == _supplierId) ? _supplierId : null;
                return DropdownButtonFormField<int?>(
                  initialValue: validSupplierId,
                  decoration: InputDecoration(
                    labelText: 'Fournisseur (facultatif)',
                    prefixIcon: const Icon(Icons.business_outlined, size: 20),
                    filled: true,
                    fillColor: AppColors.primarySurface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Aucun fournisseur'),
                    ),
                    ...suppProvider.suppliers.map(
                      (s) => DropdownMenuItem<int?>(
                        value: s.id,
                        child: Text(s.name),
                      ),
                    ),
                  ],
                  onChanged: (v) => setState(() => _supplierId = v),
                );
              },
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _priceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Prix de vente (Détail) *', suffixText: 'FCFA'),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Prix de vente obligatoire';
                      final num = double.tryParse(val.trim());
                      if (num == null || num <= 0) return 'Prix invalide (> 0)';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _costCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: "Prix d'achat", suffixText: 'FCFA'),
                    validator: (val) {
                      if (val != null && val.trim().isNotEmpty) {
                        final num = double.tryParse(val.trim());
                        if (num == null || num < 0) return "Prix d'achat invalide (>= 0)";
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // --- Tarification Gros / Demi-Gros ---
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withAlpha(30)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.sell_outlined, size: 18, color: AppColors.primary),
                      SizedBox(width: 6),
                      Text(
                        'Tarifs Gros & Demi-Gros (Optionnel)',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _priceSemiWholesaleCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Prix Demi-Gros',
                            suffixText: 'FCFA',
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _minQtySemiWholesaleCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Qté Min Demi-Gros',
                            hintText: 'ex: 5',
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _priceWholesaleCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Prix Grossiste',
                            suffixText: 'FCFA',
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _minQtyWholesaleCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Qté Min Gros',
                            hintText: 'ex: 20',
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _qtyCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Quantité *'),
              validator: (val) {
                if (val == null || val.trim().isEmpty) return 'Quantité obligatoire';
                final num = double.tryParse(val.trim());
                if (num == null || num < 0) return 'Quantité invalide (>= 0)';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _alertCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Seuil d'alerte stock",
                hintText: '5',
                prefixIcon:
                    Icon(Icons.warning_amber_outlined, color: AppColors.warning),
              ),
              validator: (val) {
                if (val != null && val.trim().isNotEmpty) {
                  final num = double.tryParse(val.trim());
                  if (num == null || num < 0) return 'Seuil invalide (>= 0)';
                }
                return null;
              },
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text(isEdit ? 'Modifier' : 'Créer le produit'),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildImagePreview() {
    if (_imageBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: Image.memory(_imageBytes!, fit: BoxFit.cover, width: 76, height: 76),
      );
    }
    if (_imagePath != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: Image.file(File(_imagePath!),
            fit: BoxFit.cover, width: 76, height: 76,
            errorBuilder: (_, _, _) => _imagePlaceholder()),
      );
    }
    return _imagePlaceholder();
  }

  Widget _imagePlaceholder() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_a_photo_outlined, color: AppColors.textLight, size: 22),
        SizedBox(height: 4),
        Text('Photo', style: TextStyle(color: AppColors.textLight, fontSize: 10)),
      ],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      AppToast.showError(context, 'Veuillez corriger les champs invalides du produit.');
      return;
    }
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _saving = true);
    try {
      final now = DateTime.now();

      // Dynamic Category Resolution
      final catText = _categoryCtrl.text.trim();
      if (catText.isNotEmpty) {
        final catProvider = context.read<CategoryProvider>();
        final existingCat = catProvider.categories
            .where((c) => c.name.toLowerCase() == catText.toLowerCase())
            .firstOrNull;
        if (existingCat != null) {
          _categoryId = existingCat.id;
        } else {
          final newCat = Category(
            name: catText,
            color: AppColors.primary.toARGB32(),
            icon: Icons.category.codePoint,
            createdAt: now,
          );
          _categoryId = await catProvider.add(newCat);
        }
      } else {
        _categoryId = null;
      }

      final savedImagePath = await _persistImage();
      final product = Product(
        id: widget.product?.id,
        name: name,
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        categoryId: _categoryId,
        supplierId: _supplierId,
        price: double.tryParse(_priceCtrl.text) ?? 0,
        priceSemiWholesale: double.tryParse(_priceSemiWholesaleCtrl.text) ?? 0,
        priceWholesale: double.tryParse(_priceWholesaleCtrl.text) ?? 0,
        minQtySemiWholesale: double.tryParse(_minQtySemiWholesaleCtrl.text) ?? 0,
        minQtyWholesale: double.tryParse(_minQtyWholesaleCtrl.text) ?? 0,
        costPrice: double.tryParse(_costCtrl.text) ?? 0,
        quantity: double.tryParse(_qtyCtrl.text) ?? 0,
        unit: 'pce',
        alertQuantity: double.tryParse(_alertCtrl.text) ?? 5,
        imagePath: savedImagePath,
        createdAt: widget.product?.createdAt ?? now,
        updatedAt: now,
      );
      await widget.onSave(product);
      if (mounted) Navigator.pop(context, product);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Une erreur est survenue. Veuillez réessayer.'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

// ---------------------------------------------------------------------------

class _ImageProcessorSheet extends StatefulWidget {
  final String sourcePath;
  final void Function(Uint8List) onConfirm;

  const _ImageProcessorSheet({required this.sourcePath, required this.onConfirm});

  @override
  State<_ImageProcessorSheet> createState() => _ImageProcessorSheetState();
}

class _ImageProcessorSheetState extends State<_ImageProcessorSheet> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Traiter l\'image', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: Image.file(File(widget.sourcePath), fit: BoxFit.contain),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final cropped = await ImageCropper().cropImage(
                    sourcePath: widget.sourcePath,
                    aspectRatioPresets: [
                      CropAspectRatioPreset.square,
                      CropAspectRatioPreset.original,
                      CropAspectRatioPreset.ratio3x2,
                      CropAspectRatioPreset.ratio4x3,
                      CropAspectRatioPreset.ratio16x9,
                    ],
                    uiSettings: [
                      AndroidUiSettings(
                        toolbarTitle: 'Recadrer l\'image',
                        toolbarColor: AppColors.primary,
                        toolbarWidgetColor: Colors.white,
                        initAspectRatio: CropAspectRatioPreset.original,
                        lockAspectRatio: false,
                      ),
                      IOSUiSettings(
                        title: 'Recadrer l\'image',
                      ),
                    ],
                  );
                  final path = cropped?.path ?? widget.sourcePath;
                  final bytes = await File(path).readAsBytes();
                  widget.onConfirm(bytes);
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('Utiliser cette image'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
