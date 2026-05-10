import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/approvisionnement.dart';
import '../providers/approvisionnement_provider.dart';
import '../providers/product_provider.dart';
import '../theme/app_theme.dart';

class ApprovisionScreen extends StatefulWidget {
  const ApprovisionScreen({super.key});

  @override
  State<ApprovisionScreen> createState() => _ApprovisionScreenState();
}

class _ApprovisionScreenState extends State<ApprovisionScreen> {
  int? _filterProductId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ApprovisionnementProvider>().load();
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
        title: const Text('Approvisionnements'),
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
        label: const Text('Approvisionner'),
      ),
    );
  }

  Widget _buildSummary(NumberFormat formatter) {
    return Consumer<ApprovisionnementProvider>(
      builder: (context, provider, _) {
        return Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Row(
            children: [
              _summaryChip(
                label: 'Total entrées',
                value: '${provider.items.length}',
                icon: Icons.arrow_downward,
                color: AppColors.success,
              ),
              const SizedBox(width: 12),
              _summaryChip(
                label: 'Montant total',
                value: formatter.format(provider.totalAmount),
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
                    style: const TextStyle(
                      color: AppColors.textLight,
                      fontSize: 11,
                    ),
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
              _filterChip(null, 'Tous', AppColors.primary),
              ...provider.products.map(
                (p) => _filterChip(p.id, p.name, AppColors.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterChip(int? productId, String label, Color color) {
    final selected = _filterProductId == productId;
    return GestureDetector(
      onTap: () {
        setState(() => _filterProductId = productId);
        context.read<ApprovisionnementProvider>().load(productId: productId);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8, bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? color : AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? color : AppColors.divider),
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
    return Consumer2<ApprovisionnementProvider, ProductProvider>(
      builder: (context, approProvider, productProvider, _) {
        if (approProvider.loading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        final items = approProvider.items;

        if (items.isEmpty) {
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
                    Icons.arrow_downward,
                    size: 48,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Aucun approvisionnement',
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Enregistrez votre premier approvisionnement',
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
                    items, productProvider, approProvider, formatter),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDataTable(
    List<Approvisionnement> items,
    ProductProvider productProvider,
    ApprovisionnementProvider approProvider,
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
        DataColumn(label: SizedBox(width: 110, child: Text('Fournisseur', style: h))),
        const DataColumn(label: SizedBox(width: 40)),
      ],
      rows: items.asMap().entries.map((entry) {
        final i = entry.key;
        final a = entry.value;
        final product = productProvider.products
            .where((p) => p.id == a.productId)
            .firstOrNull;

        return DataRow(
          color: WidgetStateProperty.all(
            i.isEven ? Colors.white : const Color(0xFFF8FBFF),
          ),
          cells: [
            DataCell(Text(
              dateFormat.format(a.date),
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
                a.quantity.toStringAsFixed(a.quantity.truncateToDouble() == a.quantity ? 0 : 1),
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            )),
            DataCell(Center(
              child: Text(
                formatter.format(a.unitPrice),
                style: const TextStyle(color: AppColors.textMedium, fontSize: 12),
              ),
            )),
            DataCell(Center(
              child: Text(
                formatter.format(a.total),
                style: const TextStyle(
                  color: AppColors.success,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            )),
            DataCell(Text(
              a.supplier ?? '—',
              style: const TextStyle(color: AppColors.textMedium, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )),
            DataCell(
              InkWell(
                onTap: () =>
                    _confirmDelete(context, a, approProvider, productProvider),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.dangerLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    color: AppColors.danger,
                    size: 14,
                  ),
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
    Approvisionnement appro,
    ApprovisionnementProvider approProvider,
    ProductProvider productProvider,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Supprimer', style: TextStyle(fontWeight: FontWeight.w700)),
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
              await approProvider.delete(appro);
              if (context.mounted) await productProvider.load();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Supprimer'),
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
      builder: (ctx) => _ApprovisionForm(
        onSave: (appro) async {
          final approProvider = context.read<ApprovisionnementProvider>();
          final productProvider = context.read<ProductProvider>();
          await approProvider.add(appro);
          await productProvider.load();
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _ApprovisionForm extends StatefulWidget {
  final Future<void> Function(Approvisionnement) onSave;

  const _ApprovisionForm({required this.onSave});

  @override
  State<_ApprovisionForm> createState() => _ApprovisionFormState();
}

class _ApprovisionFormState extends State<_ApprovisionForm> {
  final _qtyCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _supplierCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  int? _productId;
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
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
                    'Nouvel approvisionnement',
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
                          child: Text(p.name),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _productId = v),
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
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
    if (qty == null || qty <= 0 || _productId == null) return;
    setState(() => _saving = true);
    try {
      final price = double.tryParse(_priceCtrl.text) ?? 0;
      final appro = Approvisionnement(
        productId: _productId!,
        quantity: qty,
        unitPrice: price,
        total: qty * price,
        supplier: _supplierCtrl.text.trim().isEmpty
            ? null
            : _supplierCtrl.text.trim(),
        date: _date,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
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
