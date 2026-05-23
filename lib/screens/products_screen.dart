import 'dart:collection';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:excel/excel.dart' as xl;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../models/product.dart';
import '../models/category.dart'; // used in export helpers
import '../providers/category_provider.dart';
import '../providers/product_provider.dart';
import '../theme/app_theme.dart';
import 'product_detail_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  String _search = '';
  int? _filterCategoryId;
  String? _filterStatut;

  int? _pendingCategoryId;
  String? _pendingStatut;

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

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'fr_FR', symbol: 'F', decimalDigits: 0);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(context),
          _buildStats(),
          _buildFilterRow(),
          if (_selectedIds.isNotEmpty) _buildBulkBar(context),
          Expanded(child: _buildTableView(formatter)),
        ],
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Produits',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: TextField(
                      onChanged: (v) => setState(() => _search = v),
                      decoration: const InputDecoration(
                        hintText: 'Rechercher un produit...',
                        prefixIcon: Icon(Icons.search, color: AppColors.textLight, size: 20),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    tooltip: 'Import / Export',
                    icon: const Icon(Icons.import_export_rounded,
                        color: AppColors.textMedium, size: 22),
                    onSelected: (val) {
                      final all = context.read<ProductProvider>().products;
                      final cats = context.read<CategoryProvider>().categories;
                      if (val == 'import') { _importExcel(context); }
                      else if (val == 'export_excel') { _exportExcel(context, all, cats); }
                      else if (val == 'export_pdf') { _exportPdf(context, all, cats); }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem<String>(
                        value: 'import',
                        child: Row(children: [
                          const Icon(Icons.upload_file_outlined, size: 18, color: AppColors.textMedium),
                          const SizedBox(width: 10),
                          const Text('Importer Excel', style: TextStyle(fontSize: 13)),
                        ]),
                      ),
                      const PopupMenuDivider(),
                      PopupMenuItem<String>(
                        value: 'export_excel',
                        child: Row(children: [
                          const Icon(Icons.table_chart_outlined, size: 18, color: AppColors.success),
                          const SizedBox(width: 10),
                          const Text('Exporter Excel', style: TextStyle(fontSize: 13)),
                        ]),
                      ),
                      PopupMenuItem<String>(
                        value: 'export_pdf',
                        child: Row(children: [
                          const Icon(Icons.picture_as_pdf_outlined, size: 18, color: AppColors.danger),
                          const SizedBox(width: 10),
                          const Text('Exporter PDF', style: TextStyle(fontSize: 13)),
                        ]),
                      ),
                    ],
                  ),
                  const SizedBox(width: 4),
                  ElevatedButton.icon(
                    onPressed: () => _showForm(context),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Nouveau produit'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Gérez vos produits et suivez vos stocks en temps réel.',
                style: TextStyle(color: AppColors.textMedium, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Stats cards ─────────────────────────────────────────────────────────────

  Widget _buildStats() {
    return Consumer<ProductProvider>(
      builder: (_, provider, _) {
        if (provider.loading) return const SizedBox.shrink();
        final products = provider.products;
        final total = products.length;
        final enStock = products.where((p) => !p.isLowStock).length;
        final faible = products.where((p) => p.isLowStock && p.quantity > 0).length;
        final rupture = products.where((p) => p.quantity == 0).length;
        final pct = total > 0 ? (enStock * 100 / total).round() : 0;

        final cards = [
          _statCard('Total produits', '$total', 'Toutes catégories',
              Icons.inventory_2_outlined, AppColors.primary),
          _statCard('En stock', '$enStock', '$pct% des produits',
              Icons.check_circle_outline, AppColors.success),
          _statCard('Stock faible', '$faible', 'À réapprovisionner',
              Icons.warning_amber_outlined, AppColors.warning),
          _statCard('Rupture de stock', '$rupture', 'Produits indisponibles',
              Icons.block_outlined, AppColors.danger),
        ];

        return Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 600) {
                return Row(
                  children: [
                    cards[0], const SizedBox(width: 8),
                    cards[1], const SizedBox(width: 8),
                    cards[2], const SizedBox(width: 8),
                    cards[3],
                  ],
                );
              }
              return Column(
                children: [
                  Row(children: [cards[0], const SizedBox(width: 8), cards[1]]),
                  const SizedBox(height: 8),
                  Row(children: [cards[2], const SizedBox(width: 8), cards[3]]),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _statCard(String label, String value, String sub, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(35)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withAlpha(28),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                  Text(label,
                      style: const TextStyle(
                          fontSize: 10, color: AppColors.textMedium, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  Text(sub,
                      style: const TextStyle(fontSize: 9, color: AppColors.textLight),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Filter row ───────────────────────────────────────────────────────────────

  Widget _buildFilterRow() {
    return Consumer<CategoryProvider>(
      builder: (context, catProvider, _) {
        return Container(
          color: Colors.white,
          child: Column(
            children: [
              const Divider(color: AppColors.divider, height: 1),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Row(
                  children: [
                    _filterSelect<int?>(
                      label: 'Catégorie',
                      value: _pendingCategoryId,
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Toutes')),
                        ...catProvider.categories.map(
                          (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                        ),
                      ],
                      onChanged: (v) => setState(() => _pendingCategoryId = v),
                    ),
                    const SizedBox(width: 8),
                    _filterSelect<String?>(
                      label: 'Statut',
                      value: _pendingStatut,
                      items: const [
                        DropdownMenuItem(value: null, child: Text('Tous')),
                        DropdownMenuItem(value: 'en_stock', child: Text('En stock')),
                        DropdownMenuItem(value: 'faible', child: Text('Stock faible')),
                        DropdownMenuItem(value: 'rupture', child: Text('Rupture')),
                      ],
                      onChanged: (v) => setState(() => _pendingStatut = v),
                    ),
                    const SizedBox(width: 16),
                    Container(width: 1, height: 36, color: AppColors.divider),
                    const SizedBox(width: 16),
                    OutlinedButton.icon(
                      onPressed: _resetFilters,
                      icon: const Icon(Icons.refresh, size: 14),
                      label: const Text('Réinitialiser'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textMedium,
                        side: const BorderSide(color: AppColors.divider),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _applyFilters,
                      icon: const Icon(Icons.check, size: 14),
                      label: const Text('Appliquer'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
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

  Widget _filterSelect<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      width: 148,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 10, color: AppColors.textLight, fontWeight: FontWeight.w500)),
          DropdownButton<T>(
            value: value,
            items: items,
            onChanged: onChanged,
            isDense: true,
            isExpanded: true,
            underline: const SizedBox.shrink(),
            style: const TextStyle(
                color: AppColors.textDark, fontSize: 13, fontWeight: FontWeight.w500),
            icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: AppColors.textMedium),
          ),
        ],
      ),
    );
  }

  // ── Table ────────────────────────────────────────────────────────────────────

  Widget _buildTableView(NumberFormat formatter) {
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
              (_filterStatut == 'rupture' && isRupture) ||
              (_filterStatut == 'faible' && isFaible) ||
              (_filterStatut == 'en_stock' && !p.isLowStock);
          return matchSearch && matchCat && matchStatut;
        }).toList();

        if (products.isEmpty) {
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

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withAlpha(5), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: _buildDataTable(products, catProvider, productProvider, formatter),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDataTable(
    List<Product> products,
    CategoryProvider catProvider,
    ProductProvider productProvider,
    NumberFormat formatter,
  ) {
    const h = TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 12);

    return DataTable(
      headingRowHeight: 44,
      dataRowMinHeight: 80,
      dataRowMaxHeight: 80,
      columnSpacing: 8,
      horizontalMargin: 8,
      headingRowColor: WidgetStateProperty.all(AppColors.primaryLight),
      dividerThickness: 1,
      onSelectAll: (selected) => setState(() {
        if (selected == true) {
          _selectedIds.addAll(products.where((p) => p.id != null).map((p) => p.id!));
        } else {
          _selectedIds.removeWhere((id) => products.any((p) => p.id == id));
        }
      }),
      columns: [
        DataColumn(label: SizedBox(width: 172, child: Text('Produit', style: h))),
        DataColumn(label: SizedBox(width: 100, child: Text('Catégorie', style: h))),
        DataColumn(
            label: SizedBox(width: 90, child: Center(child: Text("Prix d'achat", style: h))),
            numeric: true),
        DataColumn(
            label: SizedBox(width: 90, child: Center(child: Text('Prix de vente', style: h))),
            numeric: true),
        DataColumn(
            label: SizedBox(width: 100, child: Center(child: Text('Stock actuel', style: h)))),
        DataColumn(
            label: SizedBox(width: 110, child: Center(child: Text('Valorisation', style: h)))),
        DataColumn(
            label: SizedBox(width: 80, child: Center(child: Text('Stock min.', style: h)))),
        DataColumn(
            label: SizedBox(width: 95, child: Center(child: Text('Statut', style: h)))),
        DataColumn(
            label: SizedBox(width: 90, child: Center(child: Text('Actions', style: h)))),
      ],
      rows: products.asMap().entries.map((entry) {
        final i = entry.key;
        final p = entry.value;
        final cat = catProvider.categories.where((c) => c.id == p.categoryId).firstOrNull;
        final catColor = cat != null ? Color(cat.color) : AppColors.primary;

        final isRupture = p.quantity == 0;
        final isFaible = p.isLowStock && !isRupture;
        final statusLabel = isRupture ? 'Rupture' : isFaible ? 'Stock faible' : 'En stock';
        final statusColor =
            isRupture ? AppColors.danger : isFaible ? AppColors.warning : AppColors.success;
        final stockColor = statusColor;

        final ref = 'Réf: P-${(p.id ?? 0).toString().padLeft(6, '0')}';
        final qtyStr = p.quantity.toStringAsFixed(p.quantity.truncateToDouble() == p.quantity ? 0 : 1);
        final alertStr = p.alertQuantity.toStringAsFixed(0);

        return DataRow(
          selected: p.id != null && _selectedIds.contains(p.id),
          onSelectChanged: p.id == null
              ? null
              : (sel) => setState(() {
                    if (sel == true) { _selectedIds.add(p.id!); }
                    else { _selectedIds.remove(p.id); }
                  }),
          color: WidgetStateProperty.resolveWith<Color?>((states) {
            if (states.contains(WidgetState.selected)) return AppColors.primary.withAlpha(20);
            return i.isEven ? Colors.white : const Color(0xFFF8FBFF);
          }),
          cells: [
            // Produit
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _productThumb(p, catColor, cat),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 90,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark,
                                fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        Text(ref,
                            style: const TextStyle(color: AppColors.textLight, fontSize: 10)),
                      ],
                    ),
                  ),
                ],
              ),
              onTap: () => _showForm(context, product: p),
            ),
            // Catégorie
            DataCell(
              cat != null
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: catColor.withAlpha(25),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6, height: 6,
                            decoration: BoxDecoration(color: catColor, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 5),
                          Text(cat.name,
                              style: TextStyle(
                                  color: catColor, fontWeight: FontWeight.w600, fontSize: 11)),
                        ],
                      ),
                    )
                  : const Text('—', style: TextStyle(color: AppColors.textLight)),
            ),
            // Prix d'achat
            DataCell(Center(
              child: Text(formatter.format(p.costPrice),
                  style: const TextStyle(color: AppColors.textMedium, fontSize: 12)),
            )),
            // Prix de vente
            DataCell(Center(
              child: Text(formatter.format(p.price),
                  style: const TextStyle(
                      color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 12)),
            )),
            // Stock actuel
            DataCell(Center(
              child: Text(
                qtyStr,
                style: TextStyle(color: stockColor, fontWeight: FontWeight.w700, fontSize: 12),
              ),
            )),
            // Valorisation
            DataCell(Center(
              child: Text(
                formatter.format(p.stockValue),
                style: const TextStyle(
                    color: AppColors.textDark, fontWeight: FontWeight.w600, fontSize: 12),
              ),
            )),
            // Stock min.
            DataCell(Center(
              child: Text(alertStr,
                  style: const TextStyle(color: AppColors.textMedium, fontSize: 12)),
            )),
            // Statut
            DataCell(Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(statusLabel,
                    style: TextStyle(
                        color: statusColor, fontWeight: FontWeight.w600, fontSize: 11)),
              ),
            )),
            // Actions
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
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
    );
  }

  Widget _productThumb(Product p, Color catColor, dynamic cat) {
    if (p.imagePath != null) {
      final file = File(p.imagePath!);
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          file,
          width: 72, height: 72,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _catIcon(catColor, cat),
        ),
      );
    }
    return _catIcon(catColor, cat);
  }

  Widget _catIcon(Color catColor, dynamic cat) {
    return Container(
      width: 72, height: 72,
      decoration: BoxDecoration(
        color: catColor.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        cat != null ? IconData(cat.icon, fontFamily: 'MaterialIcons') : Icons.inventory_2_outlined,
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

  void _showForm(BuildContext context, {Product? product}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ProductForm(
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

  // ── Bulk action bar ──────────────────────────────────────────────────────────

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

  // ── Export sheet ─────────────────────────────────────────────────────────────

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

  // ── Excel export ─────────────────────────────────────────────────────────────

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

  // ── PDF export ───────────────────────────────────────────────────────────────

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

  // ── Excel import ─────────────────────────────────────────────────────────────

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

  // ── Delete selected ──────────────────────────────────────────────────────────

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

class _ProductForm extends StatefulWidget {
  final Product? product;
  final Future<void> Function(Product) onSave;

  const _ProductForm({this.product, required this.onSave});

  @override
  State<_ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<_ProductForm> {
  late final _nameCtrl = TextEditingController(text: widget.product?.name ?? '');
  late final _descCtrl = TextEditingController(text: widget.product?.description ?? '');
  late final _priceCtrl = TextEditingController(
      text: widget.product != null ? widget.product!.price.toStringAsFixed(0) : '');
  late final _costCtrl = TextEditingController(
      text: widget.product != null ? widget.product!.costPrice.toStringAsFixed(0) : '');
  late final _qtyCtrl = TextEditingController(
      text: widget.product != null ? widget.product!.quantity.toStringAsFixed(0) : '');
  late final _alertCtrl = TextEditingController(
      text: widget.product != null ? widget.product!.alertQuantity.toStringAsFixed(0) : '5');
  late int? _categoryId = widget.product?.categoryId;
  String? _imagePath;
  Uint8List? _imageBytes;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _imagePath = widget.product?.imagePath;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _costCtrl.dispose();
    _qtyCtrl.dispose();
    _alertCtrl.dispose();
    super.dispose();
  }

  // ── Image helpers ────────────────────────────────────────────────────────

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

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.product != null;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
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
                  child: TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Nom du produit *',
                        hintText: 'Ex: Smartphone X12'),
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
            Consumer<CategoryProvider>(
              builder: (_, provider, _) => DropdownButtonFormField<int?>(
                initialValue: _categoryId,
                decoration: InputDecoration(
                  labelText: 'Catégorie',
                  filled: true,
                  fillColor: AppColors.primarySurface,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
                items: [
                  const DropdownMenuItem<int?>(
                      value: null, child: Text('Aucune catégorie')),
                  ...provider.categories.map((c) =>
                      DropdownMenuItem<int?>(value: c.id, child: Text(c.name))),
                ],
                onChanged: (v) => setState(() => _categoryId = v),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _priceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Prix de vente *', suffixText: 'FCFA'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _costCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: "Prix d'achat", suffixText: 'FCFA'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _qtyCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Quantité *'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _alertCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Seuil d'alerte stock",
                hintText: '5',
                prefixIcon:
                    Icon(Icons.warning_amber_outlined, color: AppColors.warning),
              ),
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
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _saving = true);
    try {
      final now = DateTime.now();
      final savedImagePath = await _persistImage();
      final product = Product(
        id: widget.product?.id,
        name: name,
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        categoryId: _categoryId,
        price: double.tryParse(_priceCtrl.text) ?? 0,
        costPrice: double.tryParse(_costCtrl.text) ?? 0,
        quantity: double.tryParse(_qtyCtrl.text) ?? 0,
        unit: 'pce',
        alertQuantity: double.tryParse(_alertCtrl.text) ?? 5,
        imagePath: savedImagePath,
        createdAt: widget.product?.createdAt ?? now,
        updatedAt: now,
      );
      await widget.onSave(product);
      if (mounted) Navigator.pop(context);
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
  static const _viewSize = 280.0;
  // 'crop' | 'fill' | 'removebg'
  String _mode = 'crop';
  bool _processing = false;

  // fill
  Uint8List? _fillPreview;

  // removebg
  Uint8List? _removedBgPreview;
  bool _removingBg = false;
  String? _removeBgError;

  // crop
  final _transformCtrl = TransformationController();
  final _repaintKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _computeFill();
  }

  // ── Fill ────────────────────────────────────────────────────────────────────

  Future<void> _computeFill() async {
    final raw = await File(widget.sourcePath).readAsBytes();
    final src = img.decodeImage(raw);
    if (src == null) return;
    final size = max(src.width, src.height);
    final canvas = img.Image(width: size, height: size, numChannels: 4);
    img.fill(canvas, color: img.ColorRgba8(255, 255, 255, 255));
    img.compositeImage(canvas, src,
        dstX: (size - src.width) ~/ 2, dstY: (size - src.height) ~/ 2);
    final resized = img.copyResize(canvas, width: 50, height: 50);
    if (mounted) {
      setState(() => _fillPreview = Uint8List.fromList(img.encodePng(resized)));
    }
  }

  // ── Background removal (on-device flood fill) ─────────────────────────────

  Future<void> _computeRemoveBg() async {
    setState(() { _removingBg = true; _removeBgError = null; _removedBgPreview = null; });
    try {
      final raw = await File(widget.sourcePath).readAsBytes();
      final result = await compute(_removeBgIsolate, raw);
      if (mounted) {
        final decoded = img.decodeImage(result);
        if (decoded != null) {
          final resized = img.copyResize(decoded, width: 50, height: 50);
          setState(() => _removedBgPreview = Uint8List.fromList(img.encodePng(resized)));
        }
      }
    } catch (_) {
      if (mounted) setState(() => _removeBgError = 'Erreur lors du traitement.');
    } finally {
      if (mounted) setState(() => _removingBg = false);
    }
  }

  // Runs in a separate isolate — must be static / top-level.
  static Uint8List _removeBgIsolate(Uint8List bytes) {
    final src = img.decodeImage(bytes);
    if (src == null) return bytes;

    final w = src.width;
    final h = src.height;

    // Ensure RGBA
    final image = img.Image(width: w, height: h, numChannels: 4);
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        final p = src.getPixel(x, y);
        image.setPixel(x, y, img.ColorRgba8(p.r.toInt(), p.g.toInt(), p.b.toInt(), 255));
      }
    }

    // Detect background color by averaging the 4 corners
    final corners = [
      image.getPixel(0, 0), image.getPixel(w - 1, 0),
      image.getPixel(0, h - 1), image.getPixel(w - 1, h - 1),
    ];
    final bgR = corners.map((c) => c.r.toInt()).reduce((a, b) => a + b) ~/ 4;
    final bgG = corners.map((c) => c.g.toInt()).reduce((a, b) => a + b) ~/ 4;
    final bgB = corners.map((c) => c.b.toInt()).reduce((a, b) => a + b) ~/ 4;
    const tolerance = 40;

    bool isBg(img.Pixel p) =>
        (p.r.toInt() - bgR).abs() <= tolerance &&
        (p.g.toInt() - bgG).abs() <= tolerance &&
        (p.b.toInt() - bgB).abs() <= tolerance;

    // BFS flood fill seeded from every border pixel that matches background
    final visited = Uint8List(w * h);
    final queue = Queue<(int, int)>();

    void enqueue(int x, int y) {
      if (x < 0 || y < 0 || x >= w || y >= h) return;
      if (visited[y * w + x] != 0) return;
      if (!isBg(image.getPixel(x, y))) return;
      visited[y * w + x] = 1;
      queue.add((x, y));
    }

    for (var x = 0; x < w; x++) { enqueue(x, 0); enqueue(x, h - 1); }
    for (var y = 0; y < h; y++) { enqueue(0, y); enqueue(w - 1, y); }

    while (queue.isNotEmpty) {
      final (x, y) = queue.removeFirst();
      final p = image.getPixel(x, y);
      image.setPixel(x, y, img.ColorRgba8(p.r.toInt(), p.g.toInt(), p.b.toInt(), 0));
      enqueue(x - 1, y); enqueue(x + 1, y);
      enqueue(x, y - 1); enqueue(x, y + 1);
    }

    return Uint8List.fromList(img.encodePng(image));
  }

  // ── Confirm ──────────────────────────────────────────────────────────────────

  Future<void> _confirm() async {
    setState(() => _processing = true);
    try {
      Uint8List? result;
      if (_mode == 'crop') {
        final boundary =
            _repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
        final uiImage = await boundary.toImage(pixelRatio: 1.0);
        final byteData = await uiImage.toByteData(format: ui.ImageByteFormat.png);
        if (byteData == null) return;
        final decoded = img.decodeImage(byteData.buffer.asUint8List());
        if (decoded == null) return;
        result = Uint8List.fromList(img.encodePng(img.copyResize(decoded, width: 50, height: 50)));
      } else if (_mode == 'fill') {
        result = _fillPreview;
      } else {
        result = _removedBgPreview;
      }
      if (result == null) return;
      widget.onConfirm(result);
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final canConfirm = _mode == 'crop' ||
        (_mode == 'fill' && _fillPreview != null) ||
        (_mode == 'removebg' && _removedBgPreview != null);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ──
            Row(
              children: [
                const Expanded(
                  child: Text("Préparer l'image",
                      style: TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w700,
                          color: AppColors.textDark)),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: AppColors.textMedium),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Mode selector (3 boutons) ──
            Row(
              children: [
                _modeBtn('Recadrer', Icons.crop, 'crop'),
                const SizedBox(width: 6),
                _modeBtn('Fond blanc', Icons.photo_size_select_actual_outlined, 'fill'),
                const SizedBox(width: 6),
                _modeBtn('Ôter le fond', Icons.auto_fix_high, 'removebg'),
              ],
            ),
            const SizedBox(height: 16),

            // ── Preview ──
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: _viewSize, height: _viewSize,
                child: _buildPreview(),
              ),
            ),
            const SizedBox(height: 8),
            _buildHint(),
            const SizedBox(height: 20),

            // ── Confirm ──
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (!canConfirm || _processing) ? null : _confirm,
                child: _processing
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Confirmer'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    switch (_mode) {
      case 'crop':
        return RepaintBoundary(
          key: _repaintKey,
          child: ClipRect(
            child: InteractiveViewer(
              transformationController: _transformCtrl,
              minScale: 1.0, maxScale: 6.0,
              clipBehavior: Clip.hardEdge,
              child: Image.file(File(widget.sourcePath),
                  width: _viewSize, height: _viewSize, fit: BoxFit.cover),
            ),
          ),
        );
      case 'fill':
        return Container(
          color: Colors.white,
          child: _fillPreview != null
              ? Image.memory(_fillPreview!, fit: BoxFit.contain)
              : const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        );
      default: // removebg
        return _buildRemoveBgPanel();
    }
  }

  Widget _buildRemoveBgPanel() {
    if (_removingBg) {
      return Container(
        color: AppColors.background,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 14),
            Text('Suppression du fond en cours…',
                style: TextStyle(color: AppColors.textMedium, fontSize: 12)),
          ],
        ),
      );
    }

    if (_removedBgPreview != null) {
      return Stack(fit: StackFit.expand, children: [
        CustomPaint(painter: _CheckerboardPainter()),
        Image.memory(_removedBgPreview!, fit: BoxFit.contain),
      ]);
    }

    // Error state with retry
    return Container(
      color: AppColors.background,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.danger.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.error_outline, color: AppColors.danger, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            _removeBgError ?? 'Une erreur est survenue.',
            style: const TextStyle(color: AppColors.textMedium, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _computeRemoveBg,
            icon: const Icon(Icons.refresh, size: 14),
            label: const Text('Réessayer'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              textStyle: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHint() {
    return Text(
      switch (_mode) {
        'crop' => 'Pincez pour zoomer · Glissez pour recadrer',
        'fill' => 'Image centrée sur fond blanc, 50×50 px',
        _ => _removedBgPreview != null
            ? 'Fond supprimé avec succès · PNG transparent 50×50 px'
            : _removingBg ? 'Analyse en cours…' : 'Appuyez sur Réessayer',
      },
      style: const TextStyle(color: AppColors.textLight, fontSize: 11),
      textAlign: TextAlign.center,
    );
  }

  Widget _modeBtn(String label, IconData icon, String mode) {
    final active = _mode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _mode = mode);
          if (mode == 'removebg' && _removedBgPreview == null && !_removingBg) {
            _computeRemoveBg();
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active ? AppColors.primary : AppColors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: active ? AppColors.primary : AppColors.divider),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: active ? Colors.white : AppColors.textMedium),
              const SizedBox(height: 3),
              Text(label,
                  style: TextStyle(
                      color: active ? Colors.white : AppColors.textMedium,
                      fontWeight: FontWeight.w600,
                      fontSize: 10),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckerboardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const sq = 14.0;
    final p1 = Paint()..color = Colors.white;
    final p2 = Paint()..color = const Color(0xFFDDDDDD);
    for (double y = 0; y < size.height; y += sq) {
      for (double x = 0; x < size.width; x += sq) {
        final rect = Rect.fromLTWH(
          x, y,
          (x + sq).clamp(0, size.width) - x,
          (y + sq).clamp(0, size.height) - y,
        );
        canvas.drawRect(rect, ((x ~/ sq) + (y ~/ sq)).isEven ? p1 : p2);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
