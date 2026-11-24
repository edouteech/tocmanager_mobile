import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../providers/category_provider.dart';
import '../providers/product_provider.dart';
import '../providers/settings_provider.dart';
import '../services/category_export_service.dart';
import '../theme/app_theme.dart';
import 'categories/category_form_modal.dart';
import 'categories/category_import_service.dart';
import 'categories/category_stats_and_filters.dart';
import 'categories/category_table_and_empty.dart';

class CategoriesScreen extends StatefulWidget {
  final VoidCallback? onBackToHome;
  const CategoriesScreen({super.key, this.onBackToHome});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  String _search = '';
  String _sortBy = 'name_asc'; // 'name_asc', 'products_desc'
  String _filterType = 'all'; // 'all', 'with_products', 'empty'

  void _showForm(BuildContext context, {Category? category}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => CategoryFormModal(
        category: category,
        onSave: (cat) async {
          final provider = context.read<CategoryProvider>();
          if (category == null) {
            await provider.add(cat);
          } else {
            await provider.update(cat);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Catégories', style: TextStyle(fontWeight: FontWeight.w700)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        leading: IconButton(
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
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Options (Export / Import)',
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.ios_share_outlined, color: AppColors.primary, size: 20),
            ),
            onSelected: (val) {
              final catProv = context.read<CategoryProvider>();
              final prodProv = context.read<ProductProvider>();
              final settings = context.read<SettingsProvider>().settings;
              if (val == 'excel') {
                CategoryExportService.exportCategoriesExcel(context, catProv.categories, prodProv.products);
              } else if (val == 'pdf') {
                CategoryExportService.exportCategoriesPdfReport(context, catProv.categories, prodProv.products, settings);
              } else if (val == 'import') {
                importCategoriesFromExcel(context);
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
                    Text('Importer des catégories'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 6),
          IconButton(
            onPressed: () => _showForm(context),
            icon: const Icon(Icons.add, color: AppColors.primary),
            tooltip: 'Nouvelle catégorie',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Consumer2<CategoryProvider, ProductProvider>(
        builder: (context, catProvider, ppProvider, _) {
          if (catProvider.loading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          final rawCats = catProvider.categories
              .where((c) => c.name.toLowerCase().contains(_search.toLowerCase()))
              .toList();

          final cats = rawCats.where((c) {
            final pCount = ppProvider.products.where((p) => p.categoryId == c.id).length;
            if (_filterType == 'with_products') return pCount > 0;
            if (_filterType == 'empty') return pCount == 0;
            return true;
          }).toList();

          if (_sortBy == 'products_desc') {
            cats.sort((a, b) {
              final cntA = ppProvider.products.where((p) => p.categoryId == a.id).length;
              final cntB = ppProvider.products.where((p) => p.categoryId == b.id).length;
              return cntB.compareTo(cntA);
            });
          } else if (_sortBy == 'name_asc') {
            cats.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
          }

          final withProductsCount = catProvider.categories
              .where((c) => ppProvider.products.any((p) => p.categoryId == c.id))
              .length;

          return Column(
            children: [
              CategoryStatsBar(
                totalCategories: catProvider.categories.length,
                categorizedProductsCount: ppProvider.products.where((p) => p.categoryId != null).length,
              ),
              CategorySearchAndSortBar(
                onSearchChanged: (v) => setState(() => _search = v),
                onSortSelected: (val) => setState(() => _sortBy = val),
              ),
              CategoryFilterChipsRow(
                filterType: _filterType,
                totalCount: catProvider.categories.length,
                withProductsCount: withProductsCount,
                emptyCount: catProvider.categories.length - withProductsCount,
                onFilterChanged: (type) => setState(() => _filterType = type),
              ),
              Expanded(
                child: cats.isEmpty
                    ? const CategoryEmptyView()
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
                              child: CategoryDataTable(
                                categories: cats,
                                products: ppProvider.products,
                                onEdit: (cat) => _showForm(context, category: cat),
                                onDelete: (cat) => showDeleteCategoryDialog(context, cat, catProvider),
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
        label: const Text('Nouvelle catégorie'),
      ),
    );
  }
}
