import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/vente.dart';
import '../providers/vente_provider.dart';
import '../providers/product_provider.dart';
import '../theme/app_theme.dart';

class VenteScreen extends StatefulWidget {
  const VenteScreen({super.key});

  @override
  State<VenteScreen> createState() => _VenteScreenState();
}

class _VenteScreenState extends State<VenteScreen> {
  int? _filterProductId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VenteProvider>().load();
    });
  }

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
        title: const Text('Ventes'),
        backgroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildSummary(formatter),
          _buildProductFilter(),
          Expanded(child: _buildTableView(formatter)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () => _showForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle vente'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  Widget _buildSummary(NumberFormat formatter) {
    return Consumer<VenteProvider>(
      builder: (context, provider, _) {
        final filtered = _filterProductId == null
            ? provider.items
            : provider.items.where((v) => v.productId == _filterProductId).toList();
        final total = filtered.fold(0.0, (sum, v) => sum + v.total);

        return Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Row(
            children: [
              _summaryChip(
                label: 'Nb ventes',
                value: '${filtered.length}',
                icon: Icons.shopping_cart_outlined,
                color: AppColors.success,
              ),
              const SizedBox(width: 12),
              _summaryChip(
                label: 'Chiffre d\'affaires',
                value: formatter.format(total),
                icon: Icons.show_chart,
                color: AppColors.primary,
                small: true,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _summaryChip({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    bool small = false,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withAlpha(40)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w700,
                      fontSize: small ? 11 : 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    label,
                    style: const TextStyle(color: AppColors.textLight, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductFilter() {
    return Consumer<ProductProvider>(
      builder: (context, provider, _) => Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _filterChip(null, 'Tous'),
              ...provider.products.map((p) => _filterChip(p.id, p.name)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterChip(int? productId, String label) {
    final selected = _filterProductId == productId;
    return GestureDetector(
      onTap: () {
        setState(() => _filterProductId = productId);
        context.read<VenteProvider>().load(productId: productId);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8, bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.success : AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? AppColors.success : AppColors.divider),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textMedium,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildTableView(NumberFormat formatter) {
    return Consumer2<VenteProvider, ProductProvider>(
      builder: (context, venteProvider, productProvider, _) {
        if (venteProvider.loading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        final items = venteProvider.items;

        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.success.withAlpha(20),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.shopping_cart_outlined,
                    size: 48,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Aucune vente',
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Enregistrez votre première vente',
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
                child: _buildDataTable(items, productProvider, venteProvider, formatter),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDataTable(
    List<Vente> items,
    ProductProvider productProvider,
    VenteProvider venteProvider,
    NumberFormat formatter,
  ) {
    const h = TextStyle(
      color: AppColors.primary,
      fontWeight: FontWeight.w700,
      fontSize: 12,
    );
    final dateFormat = DateFormat('dd/MM/yyyy', 'fr_FR');

    return DataTable(
      headingRowHeight: 44,
      dataRowMinHeight: 58,
      dataRowMaxHeight: 58,
      columnSpacing: 14,
      horizontalMargin: 14,
      headingRowColor: WidgetStateProperty.all(AppColors.primaryLight),
      dividerThickness: 1,
      columns: [
        DataColumn(label: SizedBox(width: 80, child: Text('Date', style: h))),
        DataColumn(label: SizedBox(width: 130, child: Text('Produit', style: h))),
        DataColumn(
          label: SizedBox(width: 70, child: Center(child: Text('Qté', style: h))),
          numeric: true,
        ),
        DataColumn(
          label: SizedBox(width: 90, child: Center(child: Text('P. Unitaire', style: h))),
          numeric: true,
        ),
        DataColumn(
          label: SizedBox(width: 100, child: Center(child: Text('Total', style: h))),
          numeric: true,
        ),
        DataColumn(label: SizedBox(width: 110, child: Text('Client', style: h))),
        const DataColumn(label: SizedBox(width: 40)),
      ],
      rows: items.asMap().entries.map((entry) {
        final i = entry.key;
        final v = entry.value;
        final product = productProvider.products
            .where((p) => p.id == v.productId)
            .firstOrNull;

        return DataRow(
          color: WidgetStateProperty.all(
            i.isEven ? Colors.white : const Color(0xFFF8FBFF),
          ),
          cells: [
            DataCell(Text(
              dateFormat.format(v.date),
              style: const TextStyle(color: AppColors.textMedium, fontSize: 12),
            )),
            DataCell(Text(
              product?.name ?? '—',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
                fontSize: 13,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )),
            DataCell(Center(
              child: Text(
                v.quantity.toStringAsFixed(
                    v.quantity.truncateToDouble() == v.quantity ? 0 : 1),
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            )),
            DataCell(Center(
              child: Text(
                formatter.format(v.unitPrice),
                style: const TextStyle(color: AppColors.textMedium, fontSize: 12),
              ),
            )),
            DataCell(Center(
              child: Text(
                formatter.format(v.total),
                style: const TextStyle(
                  color: AppColors.success,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            )),
            DataCell(Text(
              v.clientName ?? '—',
              style: const TextStyle(color: AppColors.textMedium, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )),
            DataCell(
              InkWell(
                onTap: () => _confirmDelete(context, v, venteProvider, productProvider),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.dangerLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.delete_outline,
                      color: AppColors.danger, size: 14),
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  void _confirmDelete(
    BuildContext context,
    Vente vente,
    VenteProvider venteProvider,
    ProductProvider productProvider,
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
              await venteProvider.delete(vente);
              if (context.mounted) await productProvider.load();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Annuler la vente'),
          ),
        ],
      ),
    );
  }

  void _showForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _VenteForm(
        onSave: (vente) async {
          final venteProvider = context.read<VenteProvider>();
          final productProvider = context.read<ProductProvider>();
          await venteProvider.add(vente);
          await productProvider.load();
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _VenteForm extends StatefulWidget {
  final Future<void> Function(Vente) onSave;

  const _VenteForm({required this.onSave});

  @override
  State<_VenteForm> createState() => _VenteFormState();
}

class _VenteFormState extends State<_VenteForm> {
  final _qtyCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _clientCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  int? _productId;
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
    final formatter =
        NumberFormat.currency(locale: 'fr_FR', symbol: 'F', decimalDigits: 0);

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
                const Expanded(
                  child: Text(
                    'Nouvelle vente',
                    style: TextStyle(
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
            Consumer<ProductProvider>(
              builder: (_, provider, _) => DropdownButtonFormField<int?>(
                initialValue: _productId,
                decoration: InputDecoration(
                  labelText: 'Produit *',
                  filled: true,
                  fillColor: AppColors.primarySurface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: provider.products
                    .map((p) => DropdownMenuItem<int?>(
                          value: p.id,
                          child: Row(
                            children: [
                              Expanded(child: Text(p.name)),
                              Text(
                                'Stock: ${p.quantity.toStringAsFixed(0)}',
                                style: const TextStyle(
                                    color: AppColors.textLight, fontSize: 11),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
                onChanged: (v) {
                  setState(() => _productId = v);
                  if (v != null) {
                    final product = provider.products
                        .where((p) => p.id == v)
                        .firstOrNull;
                    if (product != null && _priceCtrl.text.isEmpty) {
                      _priceCtrl.text = product.price.toStringAsFixed(0);
                    }
                  }
                },
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _qtyCtrl,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(labelText: 'Quantité *'),
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
                style:
                    ElevatedButton.styleFrom(backgroundColor: AppColors.success),
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
    if (qty == null || qty <= 0 || price == null || _productId == null) return;
    setState(() => _saving = true);
    try {
      final vente = Vente(
        productId: _productId!,
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
