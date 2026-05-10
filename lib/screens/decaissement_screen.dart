import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/decaissement.dart';
import '../providers/decaissement_provider.dart';
import '../theme/app_theme.dart';

class DecaissementScreen extends StatefulWidget {
  const DecaissementScreen({super.key});

  @override
  State<DecaissementScreen> createState() => _DecaissementScreenState();
}

class _DecaissementScreenState extends State<DecaissementScreen> {
  String? _filterCategory;

  static const _categories = [
    'Fournisseur',
    'Loyer',
    'Salaires',
    'Transport',
    'Divers',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DecaissementProvider>().load();
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
        title: const Text('Décaissements'),
        backgroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildSummary(formatter),
          _buildCategoryFilter(),
          Expanded(child: _buildTableView(formatter)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () => _showForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Nouveau décaissement'),
        backgroundColor: AppColors.danger,
      ),
    );
  }

  Widget _buildSummary(NumberFormat formatter) {
    return Consumer<DecaissementProvider>(
      builder: (context, provider, _) {
        final filtered = _filterCategory == null
            ? provider.items
            : provider.items
                .where((d) => d.category == _filterCategory)
                .toList();
        final total = filtered.fold(0.0, (sum, d) => sum + d.amount);

        return Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Row(
            children: [
              _summaryChip(
                label: 'Total sorties',
                value: '${filtered.length}',
                icon: Icons.arrow_upward,
                color: AppColors.danger,
              ),
              const SizedBox(width: 12),
              _summaryChip(
                label: 'Montant total',
                value: formatter.format(total),
                icon: Icons.account_balance_wallet_outlined,
                color: AppColors.purple,
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
                        color: AppColors.textLight, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _filterChip(null, 'Tous'),
            ..._categories.map((c) => _filterChip(c, c)),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String? cat, String label) {
    final selected = _filterCategory == cat;
    return GestureDetector(
      onTap: () => setState(() => _filterCategory = cat),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8, bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.danger : AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? AppColors.danger : AppColors.divider),
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
    return Consumer<DecaissementProvider>(
      builder: (context, provider, _) {
        if (provider.loading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        final items = _filterCategory == null
            ? provider.items
            : provider.items
                .where((d) => d.category == _filterCategory)
                .toList();

        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withAlpha(20),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_upward,
                    size: 48,
                    color: AppColors.danger,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Aucun décaissement',
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Enregistrez votre première sortie de caisse',
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
                child: _buildDataTable(items, provider, formatter),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDataTable(
    List<Decaissement> items,
    DecaissementProvider provider,
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
        DataColumn(label: SizedBox(width: 160, child: Text('Description', style: h))),
        DataColumn(label: SizedBox(width: 100, child: Text('Catégorie', style: h))),
        DataColumn(
          label: SizedBox(width: 100, child: Center(child: Text('Montant', style: h))),
          numeric: true,
        ),
        DataColumn(label: SizedBox(width: 100, child: Text('Référence', style: h))),
        DataColumn(
          label: SizedBox(width: 76, child: Center(child: Text('Actions', style: h))),
        ),
      ],
      rows: items.asMap().entries.map((entry) {
        final i = entry.key;
        final d = entry.value;
        final catColor = _categoryColor(d.category);

        return DataRow(
          color: WidgetStateProperty.all(
            i.isEven ? Colors.white : const Color(0xFFF8FBFF),
          ),
          cells: [
            DataCell(Text(
              dateFormat.format(d.date),
              style: const TextStyle(color: AppColors.textMedium, fontSize: 12),
            )),
            DataCell(
              SizedBox(
                width: 160,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d.description,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (d.notes != null)
                      Text(
                        d.notes!,
                        style: const TextStyle(
                          color: AppColors.textLight,
                          fontSize: 10,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ),
            DataCell(
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: catColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  d.category,
                  style: TextStyle(
                    color: catColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
            DataCell(Center(
              child: Text(
                formatter.format(d.amount),
                style: const TextStyle(
                  color: AppColors.danger,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            )),
            DataCell(Text(
              d.reference ?? '—',
              style:
                  const TextStyle(color: AppColors.textMedium, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )),
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _actionBtn(
                    icon: Icons.edit_outlined,
                    color: AppColors.primary,
                    bg: AppColors.primaryLight,
                    onTap: () => _showForm(context, decaissement: d),
                  ),
                  const SizedBox(width: 6),
                  _actionBtn(
                    icon: Icons.delete_outline,
                    color: AppColors.danger,
                    bg: AppColors.dangerLight,
                    onTap: () => _confirmDelete(context, d, provider),
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
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: color, size: 15),
      ),
    );
  }

  Color _categoryColor(String category) {
    switch (category) {
      case 'Fournisseur':
        return AppColors.primary;
      case 'Loyer':
        return AppColors.purple;
      case 'Salaires':
        return AppColors.success;
      case 'Transport':
        return const Color(0xFFF39C12);
      default:
        return AppColors.textMedium;
    }
  }

  void _confirmDelete(
    BuildContext context,
    Decaissement dec,
    DecaissementProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title:
            const Text('Supprimer', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text('Supprimer "${dec.description}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              await provider.delete(dec.id!);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _showForm(BuildContext context, {Decaissement? decaissement}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _DecaissementForm(
        decaissement: decaissement,
        categories: _categories,
        onSave: (dec) async {
          final provider = context.read<DecaissementProvider>();
          if (decaissement == null) {
            await provider.add(dec);
          } else {
            await provider.update(dec);
          }
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _DecaissementForm extends StatefulWidget {
  final Decaissement? decaissement;
  final List<String> categories;
  final Future<void> Function(Decaissement) onSave;

  const _DecaissementForm({
    this.decaissement,
    required this.categories,
    required this.onSave,
  });

  @override
  State<_DecaissementForm> createState() => _DecaissementFormState();
}

class _DecaissementFormState extends State<_DecaissementForm> {
  late final _descCtrl =
      TextEditingController(text: widget.decaissement?.description ?? '');
  late final _amountCtrl = TextEditingController(
      text: widget.decaissement != null
          ? widget.decaissement!.amount.toStringAsFixed(0)
          : '');
  late final _refCtrl =
      TextEditingController(text: widget.decaissement?.reference ?? '');
  late final _notesCtrl =
      TextEditingController(text: widget.decaissement?.notes ?? '');
  late String _category =
      widget.decaissement?.category ?? 'Divers';
  late DateTime _date = widget.decaissement?.date ?? DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _descCtrl.dispose();
    _amountCtrl.dispose();
    _refCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.decaissement != null;

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
                    isEdit ? 'Modifier le décaissement' : 'Nouveau décaissement',
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
              controller: _descCtrl,
              decoration: const InputDecoration(
                labelText: 'Description *',
                hintText: 'Ex: Paiement fournisseur',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _amountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Montant *',
                      suffixText: 'FCFA',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _category,
                    decoration: InputDecoration(
                      labelText: 'Catégorie',
                      filled: true,
                      fillColor: AppColors.primarySurface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: widget.categories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setState(() => _category = v ?? 'Divers'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _refCtrl,
              decoration: const InputDecoration(
                labelText: 'Référence',
                hintText: 'N° facture, reçu...',
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
                    backgroundColor: AppColors.danger),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : Text(isEdit ? 'Modifier' : 'Enregistrer'),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final desc = _descCtrl.text.trim();
    final amount = double.tryParse(_amountCtrl.text);
    if (desc.isEmpty || amount == null || amount <= 0) return;
    setState(() => _saving = true);
    try {
      final dec = Decaissement(
        id: widget.decaissement?.id,
        description: desc,
        amount: amount,
        category: _category,
        date: _date,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        reference:
            _refCtrl.text.trim().isEmpty ? null : _refCtrl.text.trim(),
      );
      await widget.onSave(dec);
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
