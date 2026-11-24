import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/approvisionnement.dart';
import '../../providers/supplier_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_toast.dart';
import 'approvisionnement_form_fields.dart';
import 'approvisionnement_form_product_fields.dart';

class ApprovisionFormModal extends StatefulWidget {
  final Approvisionnement? approvisionnement;
  final Future<void> Function(Approvisionnement) onSave;

  const ApprovisionFormModal({
    super.key,
    this.approvisionnement,
    required this.onSave,
  });

  @override
  State<ApprovisionFormModal> createState() => _ApprovisionFormModalState();
}

class _ApprovisionFormModalState extends State<ApprovisionFormModal> {
  final _formKey = GlobalKey<FormState>();
  final _qtyCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _paidCtrl = TextEditingController();
  final _supplierCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  int? _productId;
  int? _supplierId;
  DateTime _date = DateTime.now();
  bool _isFullPayment = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final a = widget.approvisionnement;
    if (a != null) {
      _productId = a.productId;
      _supplierId = a.supplierId;
      _qtyCtrl.text = a.quantity % 1 == 0 ? a.quantity.toInt().toString() : a.quantity.toString();
      _priceCtrl.text = a.unitPrice % 1 == 0 ? a.unitPrice.toInt().toString() : a.unitPrice.toString();
      _supplierCtrl.text = a.supplier ?? '';
      _notesCtrl.text = a.notes ?? '';
      _date = a.date;
      _isFullPayment = a.paidAmount >= a.total;
      _paidCtrl.text = a.paidAmount % 1 == 0 ? a.paidAmount.toInt().toString() : a.paidAmount.toString();
    }
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    _paidCtrl.dispose();
    _supplierCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  double get _total {
    final qty = double.tryParse(_qtyCtrl.text) ?? 0;
    final price = double.tryParse(_priceCtrl.text) ?? 0;
    return qty * price;
  }

  double get _paidAmount {
    if (_isFullPayment) return _total;
    return double.tryParse(_paidCtrl.text.trim()) ?? 0;
  }

  double get _remaining => (_total - _paidAmount).clamp(0, double.infinity);

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'fr_FR', symbol: 'F', decimalDigits: 0);

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
                      widget.approvisionnement != null
                          ? 'Modifier l\'approvisionnement'
                          : 'Nouvel approvisionnement',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textDark),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: AppColors.textMedium),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ApprovisionProductAndAmountFields(
                selectedProductId: _productId,
                qtyCtrl: _qtyCtrl,
                priceCtrl: _priceCtrl,
                total: _total,
                formatter: formatter,
                onProductChanged: (v) => setState(() => _productId = v),
                onAmountsChanged: () => setState(() {}),
              ),
              const SizedBox(height: 14),
              ApprovisionSupplierSelector(
                selectedSupplierId: _supplierId,
                supplierCtrl: _supplierCtrl,
                onSupplierChanged: (id, name) {
                  setState(() {
                    _supplierId = id;
                    if (name != null) _supplierCtrl.text = name;
                  });
                },
              ),
              const SizedBox(height: 14),
              ApprovisionPaymentSection(
                isFullPayment: _isFullPayment,
                paidCtrl: _paidCtrl,
                remaining: _remaining,
                formatter: formatter,
                onFullPaymentChanged: (full) => setState(() => _isFullPayment = full),
                onPaidChanged: () => setState(() {}),
              ),
              const SizedBox(height: 14),
              ApprovisionDateAndNotesFields(
                date: _date,
                notesCtrl: _notesCtrl,
                onPickDate: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setState(() => _date = picked);
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: AppColors.primary,
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          widget.approvisionnement != null
                              ? 'Enregistrer les modifications'
                              : 'Enregistrer l\'approvisionnement',
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
    if (_productId == null) {
      AppToast.showError(context, 'Veuillez sélectionner un produit à approvisionner.');
      return;
    }
    if (!_formKey.currentState!.validate()) {
      AppToast.showError(context, 'Veuillez vérifier vos saisies.');
      return;
    }
    final qty = double.tryParse(_qtyCtrl.text);
    if (qty == null || qty <= 0 || _productId == null) return;
    setState(() => _saving = true);
    try {
      final price = double.tryParse(_priceCtrl.text) ?? 0;
      final total = qty * price;
      final paid = _isFullPayment ? total : (double.tryParse(_paidCtrl.text.trim()) ?? 0);

      final appro = Approvisionnement(
        id: widget.approvisionnement?.id,
        productId: _productId!,
        quantity: qty,
        unitPrice: price,
        total: total,
        supplierId: _supplierId,
        supplier: _supplierCtrl.text.trim().isEmpty ? null : _supplierCtrl.text.trim(),
        paidAmount: paid,
        date: _date,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );
      await widget.onSave(appro);
      if (!mounted) return;
      await context.read<SupplierProvider>().loadSuppliers();
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) AppToast.showError(context, 'Une erreur est survenue. Veuillez réessayer.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
