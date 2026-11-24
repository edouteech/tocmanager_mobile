import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/approvisionnement.dart';
import '../../models/product.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_toast.dart';
import 'product_detail_vente_form_fields.dart';

class ProductApproInlineForm extends StatefulWidget {
  final Product product;
  final Approvisionnement? approvisionnement;
  final Future<void> Function(Approvisionnement) onSave;

  const ProductApproInlineForm({
    super.key,
    required this.product,
    this.approvisionnement,
    required this.onSave,
  });

  @override
  State<ProductApproInlineForm> createState() => _ProductApproInlineFormState();
}

class _ProductApproInlineFormState extends State<ProductApproInlineForm> {
  final _formKey = GlobalKey<FormState>();
  final _qtyCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _supplierCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final a = widget.approvisionnement;
    if (a != null) {
      _qtyCtrl.text = a.quantity % 1 == 0 ? a.quantity.toInt().toString() : a.quantity.toString();
      _priceCtrl.text = a.unitPrice % 1 == 0 ? a.unitPrice.toInt().toString() : a.unitPrice.toString();
      _supplierCtrl.text = a.supplier ?? '';
      _notesCtrl.text = a.notes ?? '';
      _date = a.date;
    }
  }

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
    final formatter = NumberFormat.currency(locale: 'fr_FR', symbol: 'F', decimalDigits: 0);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.approvisionnement != null
                          ? 'Modifier approvisionnement — ${widget.product.name}'
                          : 'Approvisionner — ${widget.product.name}',
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textDark),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _qtyCtrl,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(labelText: 'Quantité *', suffixText: widget.product.unit),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Quantité obligatoire';
                        final num = double.tryParse(val.trim());
                        if (num == null || num <= 0) return 'Quantité invalide (> 0)';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _priceCtrl,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(labelText: 'Prix unitaire', suffixText: 'FCFA'),
                      validator: (val) {
                        if (val != null && val.trim().isNotEmpty) {
                          final num = double.tryParse(val.trim());
                          if (num == null || num < 0) return 'Prix unitaire invalide';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              if (_total > 0) ...[
                const SizedBox(height: 8),
                Text('Total : ${formatter.format(_total)}',
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 14)),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: _supplierCtrl,
                decoration: const InputDecoration(labelText: 'Fournisseur', hintText: 'Nom du fournisseur'),
              ),
              const SizedBox(height: 12),
              ProductInlineDateTile(
                date: _date,
                onDateSelected: (picked) => setState(() => _date = picked),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notesCtrl,
                decoration: const InputDecoration(labelText: 'Notes', hintText: 'Remarques optionnelles'),
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
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          widget.approvisionnement != null ? 'Enregistrer les modifications' : 'Enregistrer',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
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
    if (!_formKey.currentState!.validate()) {
      AppToast.showError(context, 'Veuillez saisir une quantité valide.');
      return;
    }
    final qty = double.tryParse(_qtyCtrl.text);
    if (qty == null || qty <= 0) return;
    setState(() => _saving = true);
    try {
      final price = double.tryParse(_priceCtrl.text) ?? 0;
      final appro = Approvisionnement(
        id: widget.approvisionnement?.id,
        productId: widget.product.id!,
        quantity: qty,
        unitPrice: price,
        total: qty * price,
        supplier: _supplierCtrl.text.trim().isEmpty ? null : _supplierCtrl.text.trim(),
        date: _date,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );
      await widget.onSave(appro);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) AppToast.showError(context, 'Une erreur est survenue. Veuillez réessayer.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
