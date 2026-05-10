import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../providers/category_provider.dart';
import '../providers/product_provider.dart';
import '../theme/app_theme.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Catégories'),
        backgroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(child: _buildTableView()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle catégorie'),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: TextField(
        onChanged: (v) => setState(() => _search = v),
        decoration: const InputDecoration(
          hintText: 'Rechercher une catégorie...',
          prefixIcon: Icon(Icons.search, color: AppColors.textLight, size: 20),
        ),
      ),
    );
  }

  Widget _buildTableView() {
    return Consumer2<CategoryProvider, ProductProvider>(
      builder: (context, catProvider, ppProvider, _) {
        if (catProvider.loading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        final cats = catProvider.categories
            .where(
              (c) => c.name.toLowerCase().contains(_search.toLowerCase()),
            )
            .toList();

        if (cats.isEmpty) return _buildEmpty();

        return SingleChildScrollView(
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
        );
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
            width: 76,
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
                  IconData(cat.icon, fontFamily: 'MaterialIcons'),
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
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
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
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nom *',
                hintText: 'Ex: Électronique',
              ),
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
    );
  }

  Future<void> _save() async {
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
