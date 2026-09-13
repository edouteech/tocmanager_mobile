import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' as xl;
import '../widgets/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../providers/category_provider.dart';
import '../providers/product_provider.dart';
import '../providers/settings_provider.dart';
import '../services/category_export_service.dart';
import '../theme/app_theme.dart';
import '../utils/category_icon_helper.dart';
import 'category_detail_screen.dart';

class CategoriesScreen extends StatefulWidget {
  final VoidCallback? onBackToHome;
  const CategoriesScreen({super.key, this.onBackToHome});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  String _search = '';

  static const _palette = [
    Color(0xFF29ABE2),
    Color(0xFF27AE60),
    Color(0xFFF39C12),
    Color(0xFFE74C3C),
    Color(0xFF8E44AD),
    Color(0xFF1ABC9C),
    Color(0xFF2C3E50),
    Color(0xFFE67E22),
  ];

  static const _icons = [
    Icons.inventory_2,
    Icons.phone_android,
    Icons.restaurant,
    Icons.checkroom,
    Icons.business_center,
    Icons.local_pharmacy,
    Icons.directions_car,
    Icons.computer,
    Icons.construction,
    Icons.school,
    Icons.home,
    Icons.sports_soccer,
  ];

  String _sortBy = 'name_asc'; // 'name_asc', 'products_desc'
  String _filterType = 'all'; // 'all', 'with_products', 'empty'

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
                _importExcel(context);
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'excel',
                child: Row(
                  children: [
                    Icon(Icons.table_chart_outlined, size: 18, color: AppColors.success),
                    SizedBox(width: 8),
                    Text('Exporter Excel (.xlsx)'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'pdf',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf_outlined, size: 18, color: AppColors.danger),
                    SizedBox(width: 8),
                    Text('Rapport PDF (A4)'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
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

          final rawCats = catProvider.categories.where(
            (c) => c.name.toLowerCase().contains(_search.toLowerCase()),
          ).toList();

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

          return Column(
            children: [
              _buildStatsBar(catProvider, ppProvider),
              _buildSearchAndSortBar(),
              _buildFilterChipsRow(catProvider, ppProvider),
              Expanded(
                child: cats.isEmpty
                    ? _buildEmpty()
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
                              child: _buildDataTable(cats, catProvider, ppProvider),
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

  Widget _buildStatsBar(CategoryProvider catProvider, ProductProvider ppProvider) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withAlpha(40)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Catégories', style: TextStyle(fontSize: 11, color: AppColors.textMedium)),
                  const SizedBox(height: 2),
                  Text('${catProvider.categories.length}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.successLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.success.withAlpha(50)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Produits Catégorisés', style: TextStyle(fontSize: 11, color: AppColors.textMedium)),
                  const SizedBox(height: 2),
                  Text('${ppProvider.products.where((p) => p.categoryId != null).length}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.success)),
                ],
              ),
            ),
          ),
        ],
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
                hintText: 'Rechercher une catégorie...',
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
            tooltip: 'Trier les catégories',
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
                value: 'products_desc',
                child: Row(
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 16, color: AppColors.success),
                    SizedBox(width: 8),
                    Text('Plus de produits'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChipsRow(CategoryProvider catProvider, ProductProvider ppProvider) {
    final withProductsCount = catProvider.categories.where((c) {
      return ppProvider.products.any((p) => p.categoryId == c.id);
    }).length;
    final emptyCount = catProvider.categories.length - withProductsCount;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _filterChip('Toutes (${catProvider.categories.length})', 'all'),
            const SizedBox(width: 6),
            _filterChip('Avec produits ($withProductsCount)', 'with_products', isSuccess: true),
            const SizedBox(width: 6),
            _filterChip('Vides ($emptyCount)', 'empty'),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, String type, {bool isSuccess = false}) {
    final selected = _filterType == type;
    final activeColor = isSuccess ? AppColors.success : AppColors.primary;

    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.white : AppColors.textDark,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          fontSize: 12,
        ),
      ),
      selected: selected,
      selectedColor: activeColor,
      backgroundColor: AppColors.background,
      side: BorderSide(
        color: selected ? activeColor : AppColors.divider,
      ),
      onSelected: (val) {
        if (val) setState(() => _filterType = type);
      },
    );
  }

  Widget _buildDataTable(
    List<Category> cats,
    CategoryProvider catProvider,
    ProductProvider ppProvider,
  ) {
    const h = TextStyle(
      color: AppColors.primary,
      fontWeight: FontWeight.w700,
      fontSize: 12,
    );

    return DataTable(
      headingRowHeight: 44,
      dataRowMinHeight: 60,
      dataRowMaxHeight: 60,
      columnSpacing: 16,
      horizontalMargin: 14,
      headingRowColor: WidgetStateProperty.all(AppColors.primaryLight),
      dividerThickness: 1,
      columns: [
        const DataColumn(label: SizedBox(width: 36)),
        DataColumn(
          label: SizedBox(
            width: 130,
            child: Text('Catégorie', style: h),
          ),
        ),
        DataColumn(
          label: SizedBox(
            width: 160,
            child: Text('Description', style: h),
          ),
        ),
        DataColumn(
          label: SizedBox(
            width: 70,
            child: Center(child: Text('Produits', style: h)),
          ),
        ),
        DataColumn(
          label: SizedBox(
            width: 76,
            child: Center(child: Text('Créé le', style: h)),
          ),
        ),
        DataColumn(
          label: SizedBox(
            width: 110,
            child: Center(child: Text('Actions', style: h)),
          ),
        ),
      ],
      rows: cats.asMap().entries.map((entry) {
        final i = entry.key;
        final cat = entry.value;
        final color = Color(cat.color);
        final count =
            ppProvider.products.where((p) => p.categoryId == cat.id).length;
        final dateStr =
            '${cat.createdAt.day.toString().padLeft(2, '0')}/'
            '${cat.createdAt.month.toString().padLeft(2, '0')}/'
            '${cat.createdAt.year}';

        return DataRow(
          color: WidgetStateProperty.all(
            i.isEven ? Colors.white : const Color(0xFFF8FBFF),
          ),
          cells: [
            // Icône
            DataCell(
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withAlpha(35),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  CategoryIconHelper.getIcon(cat.icon),
                  color: color,
                  size: 18,
                ),
              ),
            ),
            // Nom
            DataCell(
              Text(
                cat.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                  fontSize: 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () => _showForm(context, category: cat),
            ),
            // Description
            DataCell(
              SizedBox(
                width: 160,
                child: Text(
                  cat.description ?? '—',
                  style: const TextStyle(
                    color: AppColors.textMedium,
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            // Nb produits
            DataCell(
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withAlpha(25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
            // Date création
            DataCell(
              Center(
                child: Text(
                  dateStr,
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
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
                      MaterialPageRoute(
                        builder: (_) => CategoryDetailScreen(category: cat),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  _actionBtn(
                    icon: Icons.edit_outlined,
                    color: AppColors.primary,
                    bg: AppColors.primaryLight,
                    onTap: () => _showForm(context, category: cat),
                  ),
                  const SizedBox(width: 6),
                  _actionBtn(
                    icon: Icons.delete_outline,
                    color: AppColors.danger,
                    bg: AppColors.dangerLight,
                    onTap: () => _confirmDelete(context, cat, catProvider),
                  ),
                ],
              ),
            ),
          ],
        );
      }).toList(),
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
        width: 30,
        height: 30,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: color, size: 15),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.category_outlined,
              size: 48,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Aucune catégorie',
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Créez votre première catégorie',
            style: TextStyle(color: AppColors.textMedium),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    Category cat,
    CategoryProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Supprimer',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Text('Supprimer la catégorie "${cat.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              await provider.delete(cat.id!);
              if (context.mounted) {
                await context.read<ProductProvider>().load();
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

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
          AppToast.showError(context, 'Fichier vide ou sans données.');
        }
        return;
      }

      int colName = 0;
      int colDesc = 1;

      // Détection automatique des colonnes par les en-têtes
      if (sheet.rows.isNotEmpty) {
        final header = sheet.rows[0];
        for (var c = 0; c < header.length; c++) {
          final title = header[c]?.value?.toString().toLowerCase().trim() ?? '';
          if (title.contains('nom') ||
              title.contains('catégorie') ||
              title.contains('categorie') ||
              title.contains('libellé') ||
              title == 'titre') {
            colName = c;
          } else if (title.contains('desc')) {
            colDesc = c;
          }
        }
      }

      final toImport = <Map<String, String>>[];
      for (var i = 1; i < sheet.rows.length; i++) {
        final row = sheet.rows[i];
        final name = (row.length > colName ? row[colName]?.value?.toString() : null)?.trim() ?? '';
        if (name.isEmpty) continue;
        final desc = (colDesc >= 0 && row.length > colDesc)
            ? (row[colDesc]?.value?.toString().trim() ?? '')
            : '';
        toImport.add({
          'name': name,
          'description': desc,
        });
      }

      if (toImport.isEmpty) {
        if (context.mounted) {
          AppToast.showError(context, 'Aucune catégorie valide trouvée.');
        }
        return;
      }

      if (!context.mounted) return;
      _showImportPreview(context, toImport);
    } catch (e) {
      if (context.mounted) {
        AppToast.showError(context, 'Erreur de lecture du fichier Excel: $e');
      }
    }
  }

  void _showImportPreview(BuildContext context, List<Map<String, String>> rows) {
    final catProvider = context.read<CategoryProvider>();
    final existingNames = {
      for (final c in catProvider.categories) c.name.toLowerCase().trim()
    };

    final newCount = rows.where((r) => !existingNames.contains(r['name']!.toLowerCase().trim())).length;
    final alreadyExistCount = rows.length - newCount;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
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
                    'Importer ${rows.length} catégorie${rows.length > 1 ? 's' : ''}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ]),
                const SizedBox(height: 6),
                Text(
                  '$newCount nouvelle${newCount > 1 ? 's' : ''} catégorie${newCount > 1 ? 's' : ''} à créer'
                  '${alreadyExistCount > 0 ? ' ($alreadyExistCount déjà existante${alreadyExistCount > 1 ? 's' : ''} ignorée${alreadyExistCount > 1 ? 's' : ''})' : ''}.',
                  style: const TextStyle(color: AppColors.textMedium, fontSize: 13),
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                ...preview.map((r) {
                  final isDuplicate = existingNames.contains(r['name']!.toLowerCase().trim());
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(children: [
                      Icon(
                        isDuplicate ? Icons.info_outline : Icons.check_circle_outline,
                        size: 18,
                        color: isDuplicate ? AppColors.warning : AppColors.success,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          r['name']!,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: isDuplicate ? AppColors.textMedium : AppColors.textDark,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isDuplicate)
                        const Text(
                          'Déjà existante',
                          style: TextStyle(fontSize: 11, color: AppColors.warning),
                        ),
                    ]),
                  );
                }),
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
    BuildContext context,
    List<Map<String, String>> rows,
  ) async {
    final catProvider = context.read<CategoryProvider>();
    final existingNames = {
      for (final c in catProvider.categories) c.name.toLowerCase().trim()
    };

    int createdCount = 0;
    for (final r in rows) {
      final key = r['name']!.toLowerCase().trim();
      if (existingNames.contains(key)) continue;

      final color = _palette[createdCount % _palette.length];
      final newCat = Category(
        name: r['name']!.trim(),
        description: r['description']?.isNotEmpty == true ? r['description'] : null,
        color: color.toARGB32(),
        icon: Icons.category.codePoint,
        createdAt: DateTime.now(),
      );

      await catProvider.add(newCat);
      existingNames.add(key);
      createdCount++;
    }

    if (context.mounted) {
      AppToast.showSuccess(
        context,
        createdCount > 0
            ? '$createdCount catégorie${createdCount > 1 ? 's' : ''} importée${createdCount > 1 ? 's' : ''} avec succès.'
            : 'Aucune nouvelle catégorie à importer (toutes déjà existantes).',
      );
      await context.read<ProductProvider>().load();
    }
  }

  void _showForm(BuildContext context, {Category? category}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _CategoryForm(
        category: category,
        palette: _palette,
        icons: _icons,
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
}

// ---------------------------------------------------------------------------

class _CategoryForm extends StatefulWidget {
  final Category? category;
  final List<Color> palette;
  final List<IconData> icons;
  final Future<void> Function(Category) onSave;

  const _CategoryForm({
    this.category,
    required this.palette,
    required this.icons,
    required this.onSave,
  });

  @override
  State<_CategoryForm> createState() => _CategoryFormState();
}

class _CategoryFormState extends State<_CategoryForm> {
  final _formKey = GlobalKey<FormState>();
  late final _nameCtrl =
      TextEditingController(text: widget.category?.name ?? '');
  late final _descCtrl =
      TextEditingController(text: widget.category?.description ?? '');
  late int _color =
      widget.category?.color ?? widget.palette.first.toARGB32();
  late int _icon = widget.category?.icon ?? widget.icons.first.codePoint;
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.category != null;
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
                    isEdit ? 'Modifier la catégorie' : 'Nouvelle catégorie',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: AppColors.textMedium),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nom de la catégorie *',
                hintText: 'Ex: Électronique',
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Le nom de la catégorie est obligatoire';
                }
                if (val.trim().length < 2) {
                  return 'Le nom doit contenir au moins 2 caractères';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Description optionnelle',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 18),
            const Text(
              'Couleur',
              style: TextStyle(
                color: AppColors.textMedium,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: widget.palette.map((c) {
                final selected = _color == c.toARGB32();
                return GestureDetector(
                  onTap: () => setState(() => _color = c.toARGB32()),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected
                            ? AppColors.textDark
                            : Colors.transparent,
                        width: 2.5,
                      ),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: c.withAlpha(100),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : [],
                    ),
                    child: selected
                        ? const Icon(Icons.check, color: Colors.white, size: 18)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
            const Text(
              'Icône',
              style: TextStyle(
                color: AppColors.textMedium,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.icons.map((icon) {
                final selected = _icon == icon.codePoint;
                final activeColor = Color(_color);
                return GestureDetector(
                  onTap: () => setState(() => _icon = icon.codePoint),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: selected
                          ? activeColor.withAlpha(30)
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected ? activeColor : AppColors.divider,
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Icon(
                      icon,
                      color: selected ? activeColor : AppColors.textMedium,
                      size: 22,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(isEdit ? 'Modifier' : 'Créer la catégorie'),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    ),
    );
  }

  Future<void> _save() async {
    if (_formKey.currentState != null && !_formKey.currentState!.validate()) {
      AppToast.showError(context, 'Veuillez saisir un nom de catégorie valide.');
      return;
    }
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _saving = true);
    try {
      final cat = Category(
        id: widget.category?.id,
        name: name,
        description:
            _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        color: _color,
        icon: _icon,
        createdAt: widget.category?.createdAt ?? DateTime.now(),
      );
      await widget.onSave(cat);
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
