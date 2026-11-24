import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/decaissement.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_toast.dart';
import 'decaissement_filter_helpers.dart';

class DecaissementFormModal extends StatefulWidget {
  final Decaissement? decaissement;
  final Future<void> Function(Decaissement) onSave;

  const DecaissementFormModal({
    super.key,
    this.decaissement,
    required this.onSave,
  });

  @override
  State<DecaissementFormModal> createState() => _DecaissementFormModalState();
}

class _DecaissementFormModalState extends State<DecaissementFormModal> {
  final _formKey = GlobalKey<FormState>();
  late final _descCtrl = TextEditingController(text: widget.decaissement?.description ?? '');
  late final _amountCtrl = TextEditingController(
      text: widget.decaissement != null ? widget.decaissement!.amount.toStringAsFixed(0) : '');
  late final _refCtrl = TextEditingController(text: widget.decaissement?.reference ?? '');
  late final _notesCtrl = TextEditingController(text: widget.decaissement?.notes ?? '');
  late String _category = widget.decaissement?.category ?? 'Divers';
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
                      isEdit ? 'Modifier le décaissement' : 'Nouveau décaissement',
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
              TextField(
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: 'Description *', hintText: 'Ex: Paiement fournisseur'),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _amountCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Montant *', suffixText: 'FCFA'),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Montant obligatoire';
                        final num = double.tryParse(val.trim());
                        if (num == null || num <= 0) return 'Montant invalide (> 0)';
                        return null;
                      },
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
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      items: kDecaissementCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (v) => setState(() => _category = v ?? 'Divers'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _refCtrl,
                decoration: const InputDecoration(labelText: 'Référence', hintText: 'N° facture, reçu...'),
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
                  decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, color: AppColors.primary, size: 18),
                      const SizedBox(width: 10),
                      Text(
                        DateFormat('dd/MM/yyyy', 'fr_FR').format(_date),
                        style: const TextStyle(color: AppColors.textDark, fontSize: 14),
                      ),
                    ],
                  ),
                ),
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
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(isEdit ? 'Modifier' : 'Enregistrer'),
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
    if (!(_formKey.currentState?.validate() ?? true)) {
      AppToast.showError(context, 'Veuillez saisir un motif et un montant valide.');
      return;
    }
    final desc = _descCtrl.text.trim();
    final amount = double.tryParse(_amountCtrl.text);
    if (desc.isEmpty || amount == null || amount <= 0) {
      AppToast.showError(context, 'Veuillez saisir un motif et un montant valide.');
      return;
    }
    setState(() => _saving = true);
    try {
      final dec = Decaissement(
        id: widget.decaissement?.id,
        description: desc,
        amount: amount,
        category: _category,
        date: _date,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        reference: _refCtrl.text.trim().isEmpty ? null : _refCtrl.text.trim(),
      );
      await widget.onSave(dec);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Une erreur est survenue. Veuillez réessayer.'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
