import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/product.dart';
import '../models/approvisionnement.dart';
import '../models/vente.dart';
import '../models/category.dart';
import '../providers/category_provider.dart';
import '../providers/approvisionnement_provider.dart';
import '../providers/vente_provider.dart';
import '../providers/product_provider.dart';
import '../theme/app_theme.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late Product _product;

  @override
  void initState() {
    super.initState();
    _product = widget.product;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ApprovisionnementProvider>().load(productId: _product.id);
      context.read<VenteProvider>().load(productId: _product.id);
    });
  }

  Future<void> _refreshProduct() async {
    final productProvider = context.read<ProductProvider>();
    await productProvider.load();
    final updated = productProvider.products
        .where((p) => p.id == _product.id)
        .firstOrNull;
    if (updated != null && mounted) setState(() => _product = updated);
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: 'F',
      decimalDigits: 0,
    );

    return Consumer<CategoryProvider>(
      builder: (context, catProvider, _) {
        final cat = catProvider.categories
            .where((c) => c.id == _product.categoryId)
            .firstOrNull;
        final catColor = cat != null ? Color(cat.color) : AppColors.primary;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: CustomScrollView(
            slivers: [
              _buildAppBar(context, catColor, cat),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildStockCard(catColor, formatter),
                    const SizedBox(height: 16),
                    _buildPriceCard(formatter),
                    const SizedBox(height: 20),
                    _buildApproSection(formatter),
                    const SizedBox(height: 20),
                    _buildVenteSection(formatter),
                    const SizedBox(height: 100),
                  ]),
                ),
              ),
            ],
          ),
          bottomNavigationBar: _buildBottomActions(context),
        );
      },
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Approvisionner'),
                onPressed: () => _showApproForm(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.shopping_cart_outlined, size: 18),
                label: const Text('Vendre'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success),
                onPressed: () => _showVenteForm(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, Color catColor, Category? cat) {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: catColor,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [catColor.withAlpha(200), catColor],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (cat != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(50),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        cat.name,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 11),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    _product.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (_product.description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _product.description!,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStockCard(Color catColor, NumberFormat formatter) {
    final ratio = _product.alertQuantity > 0
        ? (_product.quantity / (_product.alertQuantity * 3)).clamp(0.0, 1.0)
        : 1.0;
    final stockColor =
        _product.isLowStock ? AppColors.danger : AppColors.success;

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Niveau de stock',
                style: TextStyle(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: stockColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _product.isLowStock ? 'Stock faible' : 'En stock',
                  style: TextStyle(
                    color: stockColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                '${_product.quantity.toStringAsFixed(_product.quantity.truncateToDouble() == _product.quantity ? 0 : 1)} ${_product.unit}',
                style: TextStyle(
                  color: stockColor,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '/ seuil ${_product.alertQuantity.toStringAsFixed(0)}',
                style: const TextStyle(
                    color: AppColors.textLight, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: ratio,
              backgroundColor: AppColors.divider,
              valueColor: AlwaysStoppedAnimation(stockColor),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Valeur : ${formatter.format(_product.stockValue)}',
            style: const TextStyle(color: AppColors.textMedium, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceCard(NumberFormat formatter) {
    final margin = _product.price - _product.costPrice;
    final marginPct =
        _product.costPrice > 0 ? (margin / _product.costPrice * 100) : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Prix',
            style: TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _priceItem(
                  label: 'Prix de vente',
                  value: formatter.format(_product.price),
                  color: AppColors.primary,
                ),
              ),
              Expanded(
                child: _priceItem(
                  label: "Prix d'achat",
                  value: formatter.format(_product.costPrice),
                  color: AppColors.textMedium,
                ),
              ),
              Expanded(
                child: _priceItem(
                  label: 'Marge',
                  value:
                      '${formatter.format(margin)} (${marginPct.toStringAsFixed(0)}%)',
                  color: margin >= 0 ? AppColors.success : AppColors.danger,
                  smallText: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _priceItem({
    required String label,
    required String value,
    required Color color,
    bool smallText = false,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: smallText ? 11 : 16,
            fontWeight: FontWeight.w700,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(color: AppColors.textLight, fontSize: 11)),
      ],
    );
  }

  Widget _buildApproSection(NumberFormat formatter) {
    return Consumer<ApprovisionnementProvider>(
      builder: (context, provider, _) {
        return _buildHistorySection(
          title: 'Approvisionnements',
          icon: Icons.arrow_downward,
          color: AppColors.primary,
          loading: provider.loading,
          empty: 'Aucun approvisionnement enregistré',
          child: provider.items.isEmpty
              ? null
              : _buildApproTable(provider.items, formatter, provider),
        );
      },
    );
  }

  Widget _buildVenteSection(NumberFormat formatter) {
    return Consumer<VenteProvider>(
      builder: (context, provider, _) {
        return _buildHistorySection(
          title: 'Ventes',
          icon: Icons.shopping_cart_outlined,
          color: AppColors.success,
          loading: provider.loading,
          empty: 'Aucune vente enregistrée',
          child: provider.items.isEmpty
              ? null
              : _buildVenteTable(provider.items, formatter, provider),
        );
      },
    );
  }

  Widget _buildHistorySection({
    required String title,
    required IconData icon,
    required Color color,
    required bool loading,
    required String empty,
    required Widget? child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (loading)
          const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
        else if (child == null)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: Center(
              child: Text(empty,
                  style: const TextStyle(color: AppColors.textLight)),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: child,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildApproTable(
    List<Approvisionnement> items,
    NumberFormat formatter,
    ApprovisionnementProvider provider,
  ) {
    const h = TextStyle(
        color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 12);
    final dateFormat = DateFormat('dd/MM/yyyy', 'fr_FR');

    return DataTable(
      headingRowHeight: 40,
      dataRowMinHeight: 52,
      dataRowMaxHeight: 52,
      columnSpacing: 14,
      horizontalMargin: 14,
      headingRowColor: WidgetStateProperty.all(AppColors.primaryLight),
      dividerThickness: 1,
      columns: [
        DataColumn(label: SizedBox(width: 80, child: Text('Date', style: h))),
        DataColumn(
          label: SizedBox(width: 70, child: Center(child: Text('Qté', style: h))),
          numeric: true,
        ),
        DataColumn(
          label: SizedBox(width: 90, child: Center(child: Text('P. Unitaire', style: h))),
          numeric: true,
        ),
        DataColumn(
          label: SizedBox(width: 90, child: Center(child: Text('Total', style: h))),
          numeric: true,
        ),
        DataColumn(label: SizedBox(width: 110, child: Text('Fournisseur', style: h))),
        const DataColumn(label: SizedBox(width: 40)),
      ],
      rows: items.asMap().entries.map((entry) {
        final i = entry.key;
        final a = entry.value;
        return DataRow(
          color: WidgetStateProperty.all(
              i.isEven ? Colors.white : const Color(0xFFF8FBFF)),
          cells: [
            DataCell(Text(dateFormat.format(a.date),
                style: const TextStyle(
                    color: AppColors.textMedium, fontSize: 12))),
            DataCell(Center(
              child: Text(
                a.quantity.toStringAsFixed(
                    a.quantity.truncateToDouble() == a.quantity ? 0 : 1),
                style: const TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w600,
                    fontSize: 12),
              ),
            )),
            DataCell(Center(
                child: Text(formatter.format(a.unitPrice),
                    style: const TextStyle(
                        color: AppColors.textMedium, fontSize: 12)))),
            DataCell(Center(
              child: Text(formatter.format(a.total),
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12)),
            )),
            DataCell(Text(a.supplier ?? '—',
                style: const TextStyle(
                    color: AppColors.textMedium, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis)),
            DataCell(_deleteBtn(() =>
                _confirmDeleteAppro(context, a, provider))),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildVenteTable(
    List<Vente> items,
    NumberFormat formatter,
    VenteProvider provider,
  ) {
    const h = TextStyle(
        color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 12);
    final dateFormat = DateFormat('dd/MM/yyyy', 'fr_FR');

    return DataTable(
      headingRowHeight: 40,
      dataRowMinHeight: 52,
      dataRowMaxHeight: 52,
      columnSpacing: 14,
      horizontalMargin: 14,
      headingRowColor: WidgetStateProperty.all(AppColors.primaryLight),
      dividerThickness: 1,
      columns: [
        DataColumn(label: SizedBox(width: 80, child: Text('Date', style: h))),
        DataColumn(
          label: SizedBox(width: 70, child: Center(child: Text('Qté', style: h))),
          numeric: true,
        ),
        DataColumn(
          label: SizedBox(width: 90, child: Center(child: Text('P. Unitaire', style: h))),
          numeric: true,
        ),
        DataColumn(
          label: SizedBox(width: 90, child: Center(child: Text('Total', style: h))),
          numeric: true,
        ),
        DataColumn(label: SizedBox(width: 110, child: Text('Client', style: h))),
        const DataColumn(label: SizedBox(width: 40)),
      ],
      rows: items.asMap().entries.map((entry) {
        final i = entry.key;
        final v = entry.value;
        return DataRow(
          color: WidgetStateProperty.all(
              i.isEven ? Colors.white : const Color(0xFFF8FBFF)),
          cells: [
            DataCell(Text(dateFormat.format(v.date),
                style: const TextStyle(
                    color: AppColors.textMedium, fontSize: 12))),
            DataCell(Center(
              child: Text(
                v.quantity.toStringAsFixed(
                    v.quantity.truncateToDouble() == v.quantity ? 0 : 1),
                style: const TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w600,
                    fontSize: 12),
              ),
            )),
            DataCell(Center(
                child: Text(formatter.format(v.unitPrice),
                    style: const TextStyle(
                        color: AppColors.textMedium, fontSize: 12)))),
            DataCell(Center(
              child: Text(formatter.format(v.total),
                  style: const TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.w700,
                      fontSize: 12)),
            )),
            DataCell(Text(v.clientName ?? '—',
                style: const TextStyle(
                    color: AppColors.textMedium, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis)),
            DataCell(_deleteBtn(() =>
                _confirmDeleteVente(context, v, provider))),
          ],
        );
      }).toList(),
    );
  }

  Widget _deleteBtn(VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
            color: AppColors.dangerLight,
            borderRadius: BorderRadius.circular(8)),
        child: const Icon(Icons.delete_outline,
            color: AppColors.danger, size: 14),
      ),
    );
  }

  void _confirmDeleteAppro(
    BuildContext context,
    Approvisionnement appro,
    ApprovisionnementProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Supprimer',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text(
            'Supprimer cet approvisionnement ? Le stock sera mis à jour.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await provider.delete(appro);
              await _refreshProduct();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteVente(
    BuildContext context,
    Vente vente,
    VenteProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Annuler la vente',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content:
            const Text('Annuler cette vente ? Le stock sera restitué.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Non'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await provider.delete(vente);
              await _refreshProduct();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }

  void _showApproForm(BuildContext context) {
    final approProvider = context.read<ApprovisionnementProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _ApproForm(
        product: _product,
        onSave: (appro) async {
          await approProvider.add(appro);
          await _refreshProduct();
        },
      ),
    );
  }

  void _showVenteForm(BuildContext context) {
    final venteProvider = context.read<VenteProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _VenteFormInline(
        product: _product,
        onSave: (vente) async {
          await venteProvider.add(vente);
          await _refreshProduct();
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _ApproForm extends StatefulWidget {
  final Product product;
  final Future<void> Function(Approvisionnement) onSave;

  const _ApproForm({required this.product, required this.onSave});

  @override
  State<_ApproForm> createState() => _ApproFormState();
}

class _ApproFormState extends State<_ApproForm> {
  final _qtyCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _supplierCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    _supplierCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  double get _total {
    final qty = double.tryParse(_qtyCtrl.text) ?? 0;
    final price = double.tryParse(_priceCtrl.text) ?? 0;
    return qty * price;
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(
        locale: 'fr_FR', symbol: 'F', decimalDigits: 0);

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
                    'Approvisionner — ${widget.product.name}',
                    style: const TextStyle(
                      fontSize: 17,
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
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _qtyCtrl,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Quantité *',
                      suffixText: widget.product.unit,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _priceCtrl,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Prix unitaire',
                      suffixText: 'FCFA',
                    ),
                  ),
                ),
              ],
            ),
            if (_total > 0) ...[
              const SizedBox(height: 8),
              Text(
                'Total : ${formatter.format(_total)}',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _supplierCtrl,
              decoration: const InputDecoration(
                labelText: 'Fournisseur',
                hintText: 'Nom du fournisseur',
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => _date = picked);
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        color: AppColors.primary, size: 18),
                    const SizedBox(width: 10),
                    Text(
                      DateFormat('dd/MM/yyyy', 'fr_FR').format(_date),
                      style: const TextStyle(
                          color: AppColors.textDark, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesCtrl,
              decoration: const InputDecoration(
                labelText: 'Notes',
                hintText: 'Remarques optionnelles',
              ),
              maxLines: 2,
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
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Enregistrer'),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final qty = double.tryParse(_qtyCtrl.text);
    if (qty == null || qty <= 0) return;
    setState(() => _saving = true);
    try {
      final price = double.tryParse(_priceCtrl.text) ?? 0;
      final appro = Approvisionnement(
        productId: widget.product.id!,
        quantity: qty,
        unitPrice: price,
        total: qty * price,
        supplier: _supplierCtrl.text.trim().isEmpty
            ? null
            : _supplierCtrl.text.trim(),
        date: _date,
        notes:
            _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );
      await widget.onSave(appro);
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

class _VenteFormInline extends StatefulWidget {
  final Product product;
  final Future<void> Function(Vente) onSave;

  const _VenteFormInline({required this.product, required this.onSave});

  @override
  State<_VenteFormInline> createState() => _VenteFormInlineState();
}

class _VenteFormInlineState extends State<_VenteFormInline> {
  final _qtyCtrl = TextEditingController();
  final _clientCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  late final _priceCtrl = TextEditingController(
      text: widget.product.price.toStringAsFixed(0));
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    _clientCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  double get _total {
    final qty = double.tryParse(_qtyCtrl.text) ?? 0;
    final price = double.tryParse(_priceCtrl.text) ?? 0;
    return qty * price;
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(
        locale: 'fr_FR', symbol: 'F', decimalDigits: 0);

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
                    'Vendre — ${widget.product.name}',
                    style: const TextStyle(
                      fontSize: 17,
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Stock disponible : ${widget.product.quantity.toStringAsFixed(0)} ${widget.product.unit}',
                style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _qtyCtrl,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Quantité *',
                      suffixText: widget.product.unit,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _priceCtrl,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Prix unitaire *',
                      suffixText: 'FCFA',
                    ),
                  ),
                ),
              ],
            ),
            if (_total > 0) ...[
              const SizedBox(height: 8),
              Text(
                'Total : ${formatter.format(_total)}',
                style: const TextStyle(
                  color: AppColors.success,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _clientCtrl,
              decoration: const InputDecoration(
                labelText: 'Client',
                hintText: 'Nom du client (optionnel)',
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => _date = picked);
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        color: AppColors.primary, size: 18),
                    const SizedBox(width: 10),
                    Text(
                      DateFormat('dd/MM/yyyy', 'fr_FR').format(_date),
                      style: const TextStyle(
                          color: AppColors.textDark, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesCtrl,
              decoration: const InputDecoration(
                labelText: 'Notes',
                hintText: 'Remarques optionnelles',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Enregistrer la vente'),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final qty = double.tryParse(_qtyCtrl.text);
    final price = double.tryParse(_priceCtrl.text);
    if (qty == null || qty <= 0 || price == null) return;
    if (qty > widget.product.quantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Stock insuffisant (disponible : ${widget.product.quantity.toStringAsFixed(0)} ${widget.product.unit})'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final vente = Vente(
        productId: widget.product.id!,
        quantity: qty,
        unitPrice: price,
        total: qty * price,
        clientName:
            _clientCtrl.text.trim().isEmpty ? null : _clientCtrl.text.trim(),
        date: _date,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );
      await widget.onSave(vente);
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
