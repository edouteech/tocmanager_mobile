import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/product.dart';
import '../providers/category_provider.dart';
import '../providers/product_provider.dart';
import '../theme/app_theme.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  String _search = '';
  int? _filterCategoryId;

  static const _units = [
    'pce', 'kg', 'g', 'L', 'mL', 'boîte', 'carton', 'ramette', 'unité',
  ];

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: 'F',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Produits'),
        backgroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildSearchAndFilter(),
          Expanded(child: _buildTableView(formatter)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Nouveau produit'),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Column(
        children: [
          TextField(
            onChanged: (v) => setState(() => _search = v),
            decoration: const InputDecoration(
              hintText: 'Rechercher un produit...',
              prefixIcon:
                  Icon(Icons.search, color: AppColors.textLight, size: 20),
            ),
          ),
          const SizedBox(height: 8),
          Consumer<CategoryProvider>(
            builder: (context, provider, _) => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip(null, 'Tous', null),
                  ...provider.categories.map(
                    (c) => _filterChip(c.id, c.name, Color(c.color)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _filterChip(int? catId, String label, Color? color) {
    final selected = _filterCategoryId == catId;
    final activeColor = color ?? AppColors.primary;
    return GestureDetector(
      onTap: () => setState(() => _filterCategoryId = catId),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8, bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? activeColor : AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? activeColor : AppColors.divider,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textMedium,
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildTableView(NumberFormat formatter) {
    return Consumer2<ProductProvider, CategoryProvider>(
      builder: (context, productProvider, catProvider, _) {
        if (productProvider.loading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        final products = productProvider.products.where((p) {
          final matchSearch =
              p.name.toLowerCase().contains(_search.toLowerCase());
          final matchCat =
              _filterCategoryId == null || p.categoryId == _filterCategoryId;
          return matchSearch && matchCat;
        }).toList();

        if (products.isEmpty) {
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
                    Icons.inventory_2_outlined,
                    size: 48,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Aucun produit',
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Ajoutez votre premier produit',
                  style: TextStyle(color: AppColors.textMedium),
                ),
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
                child: _buildDataTable(
                  products,
                  catProvider,
                  productProvider,
                  formatter,
                ),
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
    const h = TextStyle(
      color: AppColors.primary,
      fontWeight: FontWeight.w700,
      fontSize: 12,
    );

    return DataTable(
      headingRowHeight: 44,
      dataRowMinHeight: 62,
      dataRowMaxHeight: 62,
      columnSpacing: 14,
      horizontalMargin: 14,
      headingRowColor: WidgetStateProperty.all(AppColors.primaryLight),
      dividerThickness: 1,
      columns: [
        const DataColumn(label: SizedBox(width: 36)),
        DataColumn(label: SizedBox(width: 130, child: Text('Produit', style: h))),
        DataColumn(label: SizedBox(width: 100, child: Text('Catégorie', style: h))),
        DataColumn(
          label: SizedBox(width: 90, child: Center(child: Text('P. Vente', style: h))),
          numeric: true,
        ),
        DataColumn(
          label: SizedBox(width: 90, child: Center(child: Text('P. Achat', style: h))),
          numeric: true,
        ),
        DataColumn(
          label: SizedBox(width: 90, child: Center(child: Text('Stock', style: h))),
        ),
        DataColumn(
          label: SizedBox(width: 100, child: Center(child: Text('Valeur stock', style: h))),
          numeric: true,
        ),
        DataColumn(
          label: SizedBox(width: 80, child: Center(child: Text('Alerte', style: h))),
        ),
        DataColumn(
          label: SizedBox(width: 76, child: Center(child: Text('Actions', style: h))),
        ),
      ],
      rows: products.asMap().entries.map((entry) {
        final i = entry.key;
        final p = entry.value;
        final cat = catProvider.categories
            .where((c) => c.id == p.categoryId)
            .firstOrNull;
        final catColor = cat != null ? Color(cat.color) : AppColors.primary;
        final stockColor = p.isLowStock ? AppColors.danger : AppColors.success;
        final valeur = p.quantity * p.costPrice;

        return DataRow(
          color: WidgetStateProperty.all(
            i.isEven ? Colors.white : const Color(0xFFF8FBFF),
          ),
          cells: [
            // Icône catégorie
            DataCell(
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: catColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  cat != null
                      ? IconData(cat.icon, fontFamily: 'MaterialIcons')
                      : Icons.inventory_2_outlined,
                  color: catColor,
                  size: 18,
                ),
              ),
            ),
            // Nom produit
            DataCell(
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 130,
                    child: Text(
                      p.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (p.description != null)
                    SizedBox(
                      width: 130,
                      child: Text(
                        p.description!,
                        style: const TextStyle(
                          color: AppColors.textLight,
                          fontSize: 10,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
              onTap: () => _showForm(context, product: p),
            ),
            // Catégorie badge
            DataCell(
              cat != null
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: catColor.withAlpha(25),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: catColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            cat.name,
                            style: TextStyle(
                              color: catColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    )
                  : const Text(
                      '—',
                      style: TextStyle(color: AppColors.textLight),
                    ),
            ),
            // Prix vente
            DataCell(
              Center(
                child: Text(
                  formatter.format(p.price),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            // Prix achat
            DataCell(
              Center(
                child: Text(
                  formatter.format(p.costPrice),
                  style: const TextStyle(
                    color: AppColors.textMedium,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            // Stock
            DataCell(
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: stockColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${p.quantity.toStringAsFixed(p.quantity.truncateToDouble() == p.quantity ? 0 : 1)} ${p.unit}',
                    style: TextStyle(
                      color: stockColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ),
            // Valeur stock
            DataCell(
              Center(
                child: Text(
                  formatter.format(valeur),
                  style: const TextStyle(
                    color: AppColors.purple,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            // Seuil alerte
            DataCell(
              Center(
                child: p.isLowStock
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.dangerLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.warning_amber,
                              color: AppColors.danger,
                              size: 12,
                            ),
                            SizedBox(width: 3),
                            Text(
                              'Faible',
                              style: TextStyle(
                                color: AppColors.danger,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Text(
                        '≥ ${p.alertQuantity.toStringAsFixed(0)}',
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
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 15),
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    Product product,
    ProductProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Supprimer',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
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
      builder: (ctx) => _ProductForm(
        product: product,
        units: _units,
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
}

// ---------------------------------------------------------------------------

class _ProductForm extends StatefulWidget {
  final Product? product;
  final List<String> units;
  final Future<void> Function(Product) onSave;

  const _ProductForm({this.product, required this.units, required this.onSave});

  @override
  State<_ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<_ProductForm> {
  late final _nameCtrl =
      TextEditingController(text: widget.product?.name ?? '');
  late final _descCtrl =
      TextEditingController(text: widget.product?.description ?? '');
  late final _priceCtrl = TextEditingController(
      text: widget.product != null
          ? widget.product!.price.toStringAsFixed(0)
          : '');
  late final _costCtrl = TextEditingController(
      text: widget.product != null
          ? widget.product!.costPrice.toStringAsFixed(0)
          : '');
  late final _qtyCtrl = TextEditingController(
      text: widget.product != null
          ? widget.product!.quantity.toStringAsFixed(0)
          : '');
  late final _alertCtrl = TextEditingController(
      text: widget.product != null
          ? widget.product!.alertQuantity.toStringAsFixed(0)
          : '5');
  late String _unit = widget.product?.unit ?? 'pce';
  late int? _categoryId = widget.product?.categoryId;
  bool _saving = false;

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

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.product != null;
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
                labelText: 'Nom du produit *',
                hintText: 'Ex: Smartphone X12',
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
                    borderSide: BorderSide.none,
                  ),
                ),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('Aucune catégorie'),
                  ),
                  ...provider.categories.map(
                    (c) => DropdownMenuItem<int?>(
                      value: c.id,
                      child: Text(c.name),
                    ),
                  ),
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
                      labelText: 'Prix de vente *',
                      suffixText: 'FCFA',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _costCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Prix d'achat",
                      suffixText: 'FCFA',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _qtyCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Quantité *'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _unit,
                    decoration: InputDecoration(
                      labelText: 'Unité',
                      filled: true,
                      fillColor: AppColors.primarySurface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: widget.units
                        .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                        .toList(),
                    onChanged: (v) => setState(() => _unit = v ?? 'pce'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _alertCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Seuil d'alerte stock",
                hintText: '5',
                prefixIcon: Icon(
                  Icons.warning_amber_outlined,
                  color: AppColors.warning,
                ),
              ),
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
                    : Text(isEdit ? 'Modifier' : 'Créer le produit'),
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
      final now = DateTime.now();
      final product = Product(
        id: widget.product?.id,
        name: name,
        description:
            _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        categoryId: _categoryId,
        price: double.tryParse(_priceCtrl.text) ?? 0,
        costPrice: double.tryParse(_costCtrl.text) ?? 0,
        quantity: double.tryParse(_qtyCtrl.text) ?? 0,
        unit: _unit,
        alertQuantity: double.tryParse(_alertCtrl.text) ?? 5,
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
